param (
  [Parameter(Mandatory=$true)]
  [string]$DefaultSecretName,
  [Parameter(Mandatory=$true)]
  [string]$OU_Name,
  [Parameter(Mandatory=$true)]
  [string]$OUParent
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


# Server OU links
$serverOu = "OU=DB_Servers,OU=$OU_Name,OU=$OUParent,"+$Domain

$serverLinks = (Get-GPInheritance -Target $serverOu).GpoLinks.DisplayName

$serverGpoArray = "db-firewall-policy"

foreach ($serverGpo in $serverGpoArray)
{
  if ($serverLinks -contains $serverGpo) {
    Write-Host "$($serverGpo) is already linked to the server"
  } else {
    Write-Host "$($serverGpo) is not linked to the server, linking"
    New-GPLink -Name $serverGpo -Target $serverOu
  }
}
