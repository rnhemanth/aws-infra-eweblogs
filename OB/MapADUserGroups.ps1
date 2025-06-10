param (
  [Parameter(Mandatory=$true)]
  [string]$DefaultSecretName
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

# Retrieve default secret from Secret Manager
$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $DefaultSecretName).SecretString

# Retrieve domain details
$DomainNetBios = (Get-ADDomain -Identity $FetchedDefault.domain).NetBIOSName
$DomainName = (Get-ADDomain -Identity $FetchedDefault.domain).DistinguishedName
$Domain = "OU="+$DomainNetBios+","+$DomainName

# Update dd-agent-user GMSA
$ddAgentPath = "OU=Service_Accounts,OU=Users,"+$Domain
$ddAgentName = "dd-agent-user"

# construct details of allowed principals
$ddGmsaInfo = (Get-ADServiceAccount -Identity $ddAgentName -Properties PrincipalsAllowedToRetrieveManagedPassword)
$allowedPrincipals = "lad-db-computers"
$allowedPrincipalsDn = (Get-ADGroup -Filter "Name -eq '$($allowedPrincipals)'").DistinguishedName
[array]$arrGetMgdPasswd = ($ddGmsaInfo).PrincipalsAllowedToRetrieveManagedPassword

# if the allowed principal isn't already in the allowed list, add it
if ($allowedPrincipalsDn -in $arrGetMgdPasswd) {
  Write-Host "NO UPDATE NEEDED: $($allowedPrincipals) is already in the list of allowed principals for $($ddAgentName)"
} else {
  Write-Host "Adding $($allowedPrincipals) to the list of allowed principals for $($ddAgentName)"
  $arrGetMgdPasswd += $allowedPrincipalsDn
  echo $arrGetMgdPasswd
  Set-ADServiceAccount -Identity $ddAgentName -PrincipalsAllowedToRetrieveManagedPassword $arrGetMgdPasswd
}

# Map appservice to groups
$userAppArray = "EMISWeb-LAD"
$groupNameArray = "lad-auth-db","lad-auth-app","service-accounts"

foreach ($userApp in $userAppArray) {
  foreach ($groupName in $groupNameArray) {
    Add-ADGroupMember -Identity $groupName -Members $userApp
    Write-Output "$userApp added to $groupName."
  }
}

## Add the SQL gMSA to pd-auth group
$userSqlArray = "SQLService-LAD","SQLAgent-LAD","SQLBrowser-LAD"
$groupsqlNameArray = "lad-auth-db"

foreach ($usersql in $usersqlArray) {
  foreach ($groupsqlName in $groupsqlNameArray) {
    $sqlAccountDn = (Get-ADServiceAccount -Identity $userSql -Properties PrincipalsAllowedToRetrieveManagedPassword).DistinguishedName
    Add-ADGroupMember -Identity $groupsqlName -Members $sqlAccountDn
    Write-Output "$usersql added to $groupsqlName."
  }
}
