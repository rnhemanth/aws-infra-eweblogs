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

# check if OU already exists, if not create it
$checkOU = "OU="+$pdNumber+",OU=CCMH,"+$Domain
try {
  $OUnames = (Get-ADOrganizationalUnit -Identity $checkOU).Name
  Write-Output "$OUnames already exists."
  Get-ADOrganizationalUnit -Identity $checkOU
} catch {
  $path = "OU=CCMH,"+$Domain
  # Create the OU and set it to be Protected from Accidental Deletion
  New-ADOrganizationalUnit -Name $pdNumber -Path $path -ProtectedFromAccidentalDeletion $True
  Write-Output "$pdNumber created."
  try{
    Get-ADOrganizationalUnit -Identity $checkOU
  } catch {
    Write-Output "Awaiting creation"
    Start-Sleep -Seconds 5
  }
}


$ouArray = "App_Servers","DB_Servers","Service_Accounts"

foreach ($ou in $ouArray)
{
  $checkOU = "OU="+$ou+",OU="+$pdNumber+",OU=CCMH,"+$Domain
  try {
    $OUnames = (Get-ADOrganizationalUnit -Identity $checkOU).Name
    Write-Output "$OUnames already exists."
    Get-ADOrganizationalUnit -Identity $checkOU
  } catch {
    $path = "OU="+$pdNumber+",OU=CCMH,"+$Domain
    # Create the OU and set it to be Protected from Accidental Deletion
    New-ADOrganizationalUnit -Name $ou -Path $path -ProtectedFromAccidentalDeletion $True
    Write-Output "$ou\$pdNumber created."
    try{
      Get-ADOrganizationalUnit -Identity $checkOU
    } catch {
      Write-Output "Awaiting creation"
      Start-Sleep -Seconds 5
    }
  }
}
