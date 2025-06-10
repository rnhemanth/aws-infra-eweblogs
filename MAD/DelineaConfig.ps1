param (
  [Parameter(Mandatory=$true)]
  [string]$SecretArn
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

invoke-command -ComputerName localhost -Credential $Credentials -ArgumentList @($DomainDnsRoot,$Domain,$Credentials) {
  param ($DomainDnsRoot,$Domain,$Credentials)
  try {
    Import-Module -Name ActiveDirectory -ErrorAction Stop -WarningAction SilentlyContinue
  }
  catch {
    Write-Host "Failed to install ActiveDirectory module. $_"
    exit
  }

  # Delegate permissions for password-changer
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
  Write-Host "Retreving GUID value of each schema class and attribute `n"
  try {
    $GUIDMap = @{}
    Get-ADObject -Credential $Credentials -Server $DomainDnsRoot -SearchBase ($RootDSE.SchemaNamingContext) -LDAPFilter "(schemaidguid=*)" -Properties lDAPDisplayName,schemaIDGUID |
      ForEach-Object {
          $GUIDMap[$_.lDAPDisplayName]=[System.GUID]$_.schemaIDGUID
      }
  }
  catch {
    Write-Host "Unable to retrieve GUID value of schema class and attribute"
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
    Write-Host "Unable to retrieve GUID value for each extended permission right"
    exit
  }

  #Get a reference to the OU we want to delegate
  $checkOU = "OU=Users,"+$Domain
  $OU = (Get-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -Identity $checkOU).DistinguishedName
  Write-Host "OU=$OU `n"

  #Get the SID values of password-changer user
  $delegateUser = 'password-changer'
  $userSid = (Get-ADUser -Credential $Credentials -Server $DomainDnsRoot -Filter "SamAccountName -eq '$delegateUser'").SID
  Write-Host "UserSID=$userSid `n"

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

  #Get a copy of the current DACL on the OU
  Write-Host "Getting $OU ACL `n"
  $acl = Get-ACL -Path ($OU)

  #Create an Access Control Entry for new permission we wish to add
  Write-Host "Adding $OU ACL permissions `n"
  # Add writeproperty rules on lockoutime, pwdlastset and UserAccountControl
  $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $userSid,"WriteProperty","Allow",$GUIDMap["lockoutTime"],"Descendents",$GUIDMap["user"]))
  $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $userSid,"WriteProperty","Allow",$GUIDMap["pwdLastSet"],"Descendents",$GUIDMap["user"]))
  $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $userSid,"WriteProperty","Allow",$GUIDMap["UserAccountControl"],"Descendents",$GUIDMap["user"]))

  #Allow readproperty rules on lockoutime, pwdlastset and UserAccountControl
  $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $userSid,"ReadProperty","Allow",$GUIDMap["UserAccountControl"],"Descendents",$GUIDMap["user"]))
  $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $userSid,"ReadProperty","Allow",$GUIDMap["pwdLastSet"],"Descendents",$GUIDMap["user"]))
  $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $userSid,"ReadProperty","Allow",$GUIDMap["lockoutTime"],"Descendents",$GUIDMap["user"]))

  #Allow reset password and change password on all descendent user objects
  $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $userSID,"ExtendedRight","Allow",$extendedrightsmap["Reset Password"],"Descendents",$GUIDMap["user"]))
  $acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $userSID,"ExtendedRight","Allow",$extendedrightsmap["Change Password"],"Descendents",$GUIDMap["user"]))

  #Re-apply the modified DACL to the OU
  Write-Host "Setting $OU ACL permissions `n"
  Set-ACL -Path ("RemoteAD:\"+($OU)) -ACLObject:$acl

  #Delay for permission changes to replicate
  Write-Host "Applying $OU ACL permissions... `n"
  Start-Sleep -s 15

  Write-Host "ACL rules applied to:`n $OU`nFor:`n $delegateuser"
}