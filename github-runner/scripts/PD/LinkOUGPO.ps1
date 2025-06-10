param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
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


# App OU GP links
$appOu = "OU=App_Servers,OU="+$pdNumber+",OU=GP,"+$Domain

$appLinks = (Get-GPInheritance -Target $appOu).GpoLinks.DisplayName

$appGpoArray = "gp-app-settings","app-firewall-policy"

foreach ($appGpo in $appGpoArray)
{
  if ($appLinks -contains $appGpo) {
    Write-Host "$($appGpo) is already linked to the app server"
  } else {
    Write-Host "$($appGpo) is not linked to the app server, linking"
    New-GPLink -Name $appGpo -Target $appOu
  }
}

# DB OU GP links
$dbOu = "OU=DB_Servers,OU="+$pdNumber+",OU=GP,"+$Domain

$dbLinks = (Get-GPInheritance -Target $dbOu).GpoLinks.DisplayName

$dbGpoArray = "gp-db-settings","db-firewall-policy"

foreach ($dbGpo in $dbGpoArray)
{
  if ($dbLinks -contains $dbGpo) {
    Write-Host "$($dbGpo) is already linked to the db server"
  } else {
    Write-Host "$($dbGpo) is not linked to the db server, linking"
    New-GPLink -Name $dbGpo -Target $dbOu
  }
}
