param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
  [Parameter(Mandatory=$true)]
  [string]$EnvironmentType,
  [Parameter(Mandatory=$true)]
  [string]$DefaultSecretName,
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


# Retrieve default secret from Secret Manager
#$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $DefaultSecretName).SecretString
$FetchedDefault = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $DefaultSecretName | ConvertFrom-Json).SecretString

# Retrieve domain details
$DomainName = (Get-ADDomain -Identity $FetchedDefault.domain).DistinguishedName
$DomainNetBios = (Get-ADDomain -Identity $FetchedDefault.domain).NetBIOSName
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedDefault.domain).DNSRoot
$Domain = "OU="+$DomainNetBios+","+$DomainName

# check if OU already exists, if not create it
$checkOU = "OU="+$pdNumber+",OU=$EnvironmentType,"+$Domain
try {
  $OUnames = (Get-ADOrganizationalUnit -Server $DomainDnsRoot -Identity $checkOU).Name
  Write-Output "$OUnames already exists."
  Get-ADOrganizationalUnit -Server $DomainDnsRoot -Identity $checkOU
} catch {
  $path = "OU=$EnvironmentType,"+$Domain
  # Create the OU and set it to be Protected from Accidental Deletion
  New-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -Name $pdNumber -Path $path -ProtectedFromAccidentalDeletion $True
  Write-Output "$pdNumber created."
  try{
    Get-ADOrganizationalUnit -Server $DomainDnsRoot -Identity $checkOU
  } catch {
    Write-Output "Awaiting creation"
    Start-Sleep -Seconds 5
  }
}


$ouArray = "App_Servers","DB_Servers","Service_Accounts"

foreach ($ou in $ouArray)
{
  $checkOU = "OU="+$ou+",OU="+$pdNumber+",OU=$EnvironmentType,"+$Domain
  try {
    $OUnames = (Get-ADOrganizationalUnit -Server $DomainDnsRoot -Identity $checkOU).Name
    Write-Output "$OUnames already exists."
    Get-ADOrganizationalUnit -Server $DomainDnsRoot -Identity $checkOU
  } catch {
    $path = "OU="+$pdNumber+",OU=$EnvironmentType,"+$Domain
    # Create the OU and set it to be Protected from Accidental Deletion
    New-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -Name $ou -Path $path -ProtectedFromAccidentalDeletion $True
    Write-Output "$ou\$pdNumber created."
    try{
      Get-ADOrganizationalUnit -Server $DomainDnsRoot -Identity $checkOU
    } catch {
      Write-Output "Awaiting creation"
      Start-Sleep -Seconds 5
    }
  }
}
