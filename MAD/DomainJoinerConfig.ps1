param (
  [Parameter(Mandatory=$true)]
  [string]$SecretArn,
  [Parameter(Mandatory=$true)]
  [string[]]$DomainJoinerOUs
)

$features = ("RSAT-AD-PowerShell","RSAT-AD-AdminCenter","RSAT-ADDS-Tools","GPMC","RSAT-DNS-Server")
foreach ($feature in $features) {
  if ((Get-WindowsFeature $feature).installed -ne 'True') {
    try {
      Write-Output "Installing feature $feature"
      Install-WindowsFeature -Name $feature -ErrorAction Stop
    }
    catch {
      Write-Error "Failed to install feature $_"
      exit
    }
  }
  if ((Get-Module -Name ActiveDirectory -ListAvailable).Name -eq $null) {
    try {
      Write-Output "Importing module ActiveDirectory"
      Import-Module -Name ActiveDirectory -ErrorAction Stop
    }
    catch { Write-Error "Failed to import ActiveDirectory module. $_" }
  }
}

Write-Output "All modules and features present."

# Retrieve domain admin password from Secret Manager
#$FetchedSecret = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $SecretArn).SecretString
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value --secret-id $SecretArn | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

# Join Domain
if ((Get-WmiObject win32_computersystem).partofdomain -eq $false)  {
  # Add-Computer -DomainName $FetchedSecret.domain -Credential $Credentials -force -Options JoinWithNewName,AccountCreate -restart
  Write-Output "Not part of a domain. Exiting script."
  exit
}
else {
  $DomainOutput = (Get-WmiObject win32_computersystem).Domain
  Write-Output "Part of domain $DomainOutput."
}

# Retrieve domain details
$DomainName = (Get-ADDomain -Identity $FetchedSecret.domain).DistinguishedName
$DomainNetBios = (Get-ADDomain -Identity $FetchedSecret.domain).NetBIOSName
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot
$Domain = "OU="+$DomainNetBios+","+$DomainName

if ([string]::IsNullOrEmpty($DomainNetBios)) {
  Write-Error "Failed to retrieve domain details. Script cannot proceed."
  exit
}

invoke-command -ComputerName localhost -Credential $Credentials -ArgumentList @($DomainDnsRoot,$Domain,$Credentials,$DomainJoinerOUs) {
  param ($DomainDnsRoot,$Domain,$Credentials,$DomainJoinerOUs)
  try {
    Import-Module -Name ActiveDirectory -ErrorAction Stop -WarningAction SilentlyContinue
  } catch {
    Write-Host "Failed to install ActiveDirectory module. $_"
    exit
  }

  # Delegate permissions for domain-joiners
  ##Get a reference to the RootDSE of the current domain
  Write-Host "Retreving RootDSE information `n"
  try {
    $RootDSE = Get-ADRootDSE -Credential $Credentials -Server $DomainDnsRoot
  }
  catch {
    Write-Host "Unable to get Directory Server information tree $_"
      exit
  }

  #Retreving GUID value of each schema class and attribute
  Write-Host "Retreving GUID value of each schema class and attribute`n"
  try {
    $GUIDMap = @{}
    Get-ADObject -Credential $Credentials -Server $DomainDnsRoot -SearchBase ($RootDSE.SchemaNamingContext) -LDAPFilter "(schemaidguid=*)" -Properties lDAPDisplayName,schemaIDGUID |
      ForEach-Object {
          $GUIDMap[$_.lDAPDisplayName]=[System.GUID]$_.schemaIDGUID
      }
  }
  catch {
    Write-Host "Unable to retrieve GUID value of schema class and attribute $_"
    exit
  }

  #Retreving GUID value for each extended permission right
  Write-Host  "Retreving GUID value for each extended permission right `n"
  try {
    $ExtendedRightsMap = @{}
    Get-ADObject -Credential $Credentials -Server $DomainDnsRoot -SearchBase ($RootDSE.ConfigurationNamingContext) -LDAPFilter "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName,rightsGuid |
        ForEach-Object {
            $ExtendedRightsMap[$_.displayName]=[System.GUID]$_.rightsGuid
        }
  }
  catch {
    Write-Host "Unable to retrieve GUID value for each extended permission right $_"
    exit
  }

  #Get the SID values of domain-joiners user
  $delegateGroup = 'domain-joiners'
  $groupSid = (Get-ADGroup -Credential $Credentials -Server $DomainDnsRoot -Filter "SamAccountName -eq '$delegateGroup'").SID
  Write-Host "GroupSID=$groupSid `n"

  #set location to AD:
  Write-Host "Setting Location to RemoteAD: `n"
  try {
      New-PSDrive -Credential $Credentials -Name RemoteAD -PSProvider ActiveDirectory -Server $DomainDnsRoot -Scope Global -root "//RootDSE/"
      Set-Location RemoteAD:
  }
  catch {
      Write-Host "Unable to set location to RemoteAD: $_"
      exit
  }

  foreach ($OU in $DomainJoinerOUs) {
    #Get a reference to the OUs we want to delegate
    $checkOU = $OU+","+$Domain
    $OU_DN = (Get-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -Identity $checkOU).DistinguishedName
    Write-Host "OU=$OU_DN `n"

    #Get a copy of the current DACL on the OUs
    Write-Host "Getting $OU_DN ACL `n"
    $acl = Get-ACL -Path ($OU_DN)

    # Add new DACL entries for domain join delegated permissions
    Write-Host "Adding $OU_DN ACL permissions `n"
    ### Uses ActiveDirectoryAccessRule(IdentityReference, ActiveDirectoryRights, AccessControlType, ActiveDirectorySecurityInheritance, Guid)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $groupSid,"ListChildren","Allow","Descendents",$GUIDMap["computer"]))
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $groupSid,"ReadProperty","Allow","Descendents",$GUIDMap["computer"]))
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $groupSid,"GenericWrite","Allow","Descendents",$GUIDMap["computer"]))
    
    ### Uses ActiveDirectoryAccessRule(IdentityReference, ActiveDirectoryRights, AccessControlType, Guid, ActiveDirectorySecurityInheritance)
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $groupSid,"CreateChild","Allow",$GUIDMap["computer"],"All"))
    $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $groupSid,"DeleteChild","Allow",$GUIDMap["computer"],"All"))

    #Re-apply the modified DACL to the OUs
    Write-Host "Setting $OU_DN ACL permissions `n"
    Set-ACL -Path ("RemoteAD:\"+($OU_DN)) -ACLObject:$acl

    #Delay for permission changes to replicate
    Write-Host "Applying $OU_DN ACL permissions... `n"
    Start-Sleep -s 15

    $OU_DN = (Get-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -Identity $checkOU).DistinguishedName
    Write-Host "ACL rules applied to:`n $OU_DN`nFor:`n $delegateGroup"
  }
}