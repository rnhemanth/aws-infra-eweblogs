param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
  [Parameter(Mandatory=$true)]
  # [string]$DefaultSecretName,
  # [Parameter(Mandatory=$true)]
  [string]$EnvironmentType,
  [Parameter(Mandatory=$true)]
  [string]$SecretArn
)

# Import ActiveDirectory module
try {
  Import-Module -Name ActiveDirectory -ErrorAction Stop
} catch {
  if ((Get-WindowsFeature RSAT-DNS-Server).installed -ne 'True') {
    try {
      Install-WindowsFeature -Name GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server -ErrorAction Stop
      Import-Module -Name ActiveDirectory -ErrorAction Stop
    } catch {
      Write-Error "Failed to install ActiveDirectory module. $_"
      exit
    }
  } else {
    Write-Error "Failed to import ActiveDirectory module. $_"
    exit
  }
}

# Retrieve domain admin password from Secret Manager
#$FetchedSecret = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $SecretArn).SecretString
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $SecretArn | ConvertFrom-Json).SecretString
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

# Update dd-agent-user GMSA
$pdNumberLower = $pdNumber.ToLower()
$ddAgentPath = "OU=Service_Accounts,OU=Users,"+$Domain
$ddAgentName = "dd-agent-user"

# construct details of allowed principals
$ddGmsaInfo = (Get-ADServiceAccount -Server $DomainDnsRoot -Identity $ddAgentName -Properties PrincipalsAllowedToRetrieveManagedPassword)
$allowedPrincipals = $pdNumberLower+"-db-computers"
$allowedPrincipalsDn = (Get-ADGroup -Server $DomainDnsRoot -Filter "Name -eq '$($allowedPrincipals)'").DistinguishedName
[array]$arrGetMgdPasswd = ($ddGmsaInfo).PrincipalsAllowedToRetrieveManagedPassword

# if the allowed principal isn't already in the allowed list, add it
if ($allowedPrincipalsDn -in $arrGetMgdPasswd) {
  Write-Host "NO UPDATE NEEDED: $($allowedPrincipals) is already in the list of allowed principals for $($ddAgentName)"
} else {
  Write-Host "Adding $($allowedPrincipals) to the list of allowed principals for $($ddAgentName)"
  $arrGetMgdPasswd += $allowedPrincipalsDn
  echo $arrGetMgdPasswd
  Set-ADServiceAccount -Credential $Credentials -Server $DomainDnsRoot -Identity $ddAgentName -PrincipalsAllowedToRetrieveManagedPassword $arrGetMgdPasswd
}

# Map appservice to groups
$userAppArray = "EMISWeb-$($pdNumber)","Scheduler-$($pdNumber)","EMAS-$($pdNumber)","SDS-$($pdNumber)"
$groupNameArray = "$EnvironmentType-auth-db","$EnvironmentType-auth-app","service-accounts","ccmh-auth-access"

foreach ($userApp in $userAppArray) {
  foreach ($groupName in $groupNameArray) {
    Add-ADGroupMember -Credential $Credentials -Server $DomainDnsRoot -Identity $groupName -Members $userApp
    Write-Output "$userApp added to $groupName."
  }
}

## Add the SQL gMSA to pd-auth-db group
$userSqlArray = "SQLService-$($pdNumber)","SQLAgent-$($pdNumber)","SQLBrowser-$($pdNumber)"
$groupsqlNameArray = "$EnvironmentType-auth-db","ccmh-auth-access"

foreach ($usersql in $usersqlArray) {
  foreach ($groupsqlName in $groupsqlNameArray) {
    $sqlAccountDn = (Get-ADServiceAccount -Server $DomainDnsRoot -Identity $userSql -Properties PrincipalsAllowedToRetrieveManagedPassword).DistinguishedName
    Add-ADGroupMember -Credential $Credentials -Server $DomainDnsRoot -Identity $groupsqlName -Members $sqlAccountDn
    Write-Output "$usersql added to $groupsqlName."
  }
}
