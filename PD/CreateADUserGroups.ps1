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

# Construct group OU
$pdNumberLower = $pdNumber.ToLower()
$dbGroupName = $pdNumberLower+"-db-computers"
$groupPath = "OU=Computer_Groups,OU=Computers,"+$Domain

# Check if the group already exists in Active Directory
if (Get-ADGroup -Filter "Name -eq '$($dbGroupName )'") {
  Write-Output "$($dbGroupName) already exists."
  Get-ADGroup -Identity $dbGroupName
}
else {
  # If the group doesn't exist, create it
  New-ADGroup -Name $dbGroupName  -SamAccountName $dbGroupName  -GroupCategory "Security" `
  -GroupScope "Global" -DisplayName $dbGroupName  -Path $groupPath -Description "Used to manage gMSA access to GP db servers."
  Write-Output "$($dbGroupName) created."
  Get-ADGroup -Identity $dbGroupName
}
