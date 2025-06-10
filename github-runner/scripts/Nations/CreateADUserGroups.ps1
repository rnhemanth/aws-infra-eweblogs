param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
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

# Construct group OU
$pdNumberLower = $pdNumber.ToLower()
$dbGroupName = $pdNumberLower+"-db-computers"
$groupPath = "OU=Computer_Groups,OU=Computers,"+$Domain

# Check if the group already exists in Active Directory
if (Get-ADGroup -Server $DomainDnsRoot -Filter "Name -eq '$($dbGroupName )'") {
  Write-Output "$($dbGroupName) already exists."
  Get-ADGroup -Server $DomainDnsRoot -Identity $dbGroupName
}
else {
  # If the group doesn't exist, create it
  New-ADGroup -Credential $Credentials -Server $DomainDnsRoot -Name $dbGroupName  -SamAccountName $dbGroupName  -GroupCategory "Security" `
  -GroupScope "Global" -DisplayName $dbGroupName  -Path $groupPath -Description "Used to manage gMSA access to db servers."
  Write-Output "$($dbGroupName) created."
  Get-ADGroup -Server $DomainDnsRoot -Identity $dbGroupName
}
