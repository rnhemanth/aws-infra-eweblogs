param (
  [Parameter(Mandatory=$true)]
  [string]$DefaultSecretName,
  [Parameter(Mandatory=$true)]
  [string]$GroupName
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
$serverGroupName = "$GroupName"
$groupPath = "OU=Computer_Groups,OU=Computers,"+$Domain

# Check if the group already exists in Active Directory
if (Get-ADGroup -Filter "Name -eq '$($serverGroupName )'") {
  Write-Output "$($serverGroupName) already exists."
  Get-ADGroup -Identity $serverGroupName
}
else {
  # If the group doesn't exist, create it
  New-ADGroup -Name $serverGroupName  -SamAccountName $serverGroupName  -GroupCategory "Security" `
  -GroupScope "Global" -DisplayName $serverGroupName  -Path $groupPath -Description "Used to manage gMSA access to GP db servers."
  Write-Output "$($serverGroupName) created."
  Get-ADGroup -Identity $serverGroupName
}
