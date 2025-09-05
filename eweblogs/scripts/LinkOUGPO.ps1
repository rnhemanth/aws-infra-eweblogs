param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
  [Parameter(Mandatory=$true)]
  [string]$EnvironmentType,
  [Parameter(Mandatory=$true)]
  [string]$DefaultSecretName,
  [Parameter(Mandatory=$true)]
  [string]$ServiceAccountPrefix,
  [Parameter(Mandatory=$true)]
  [string]$OuStructure
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
# $FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value --secret-id $SecretArn | ConvertFrom-Json).SecretString
# $username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
# $Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

$FetchedDefault = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $DefaultSecretName | ConvertFrom-Json).SecretString
$Password = (ConvertTo-SecureString $FetchedDefault.password -AsPlainText -Force)

# Retrieve domain details
$DomainName = (Get-ADDomain -Identity $FetchedDefault.domain).DistinguishedName
$DomainNetBios = (Get-ADDomain -Identity $FetchedDefault.domain).NetBIOSName
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedDefault.domain).DNSRoot
$Domain = "OU="+$DomainNetBios+","+$DomainName

if ([string]::IsNullOrEmpty($DomainNetBios)) {
  Write-Error "Failed to retrieve domain details. Script cannot proceed."
  exit
}


$appGpoArray = "$EnvironmentType-db-settings","db-firewall-policy"

    # App OU GP links
    $appOu = $OuStructure.Replace("Service_Accounts", "SQL_Servers") + "," + $Domain

    $appLinks = (Get-ADOrganizationalUnit -Server $DomainDnsRoot -filter "distinguishedName -eq '$appOU'" | Get-GPInheritance -Domain $DomainDnsRoot).GpoLinks.DisplayName

    foreach ($appGpo in $appGpoArray) {
      if ($appLinks -contains $appGpo) {
        Write-Host "$($appGpo) is already linked to the app servers OU."
      } else {
        Write-Host "$($appGpo) is not linked to the app servers OU. `n"
        New-GPLink -Server $DomainDnsRoot -Name $appGpo -Target $appOu
        Write-Output "GP-Link created. GPO = $($appGpo); Path = $appOu `n"
      }
    }
