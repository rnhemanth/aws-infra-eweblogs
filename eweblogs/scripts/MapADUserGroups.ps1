param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
  [Parameter(Mandatory=$true)]
  [string]$EnvironmentType,
  [Parameter(Mandatory=$true)]
  [string]$DefaultSecretName,
  [Parameter(Mandatory=$true)]
  [string]$authaccessgroup
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
# $FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $SecretArn | ConvertFrom-Json).SecretString
# $username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
# $Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

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

$ServiceAccount = $pdNumber.ToUpper()

## Add the SQL gMSA to pd-auth-db group
$gmsaNameArray = "SQLService-$($ServiceAccount)","SQLAgent-$($ServiceAccount)","SQLBrowser-$($ServiceAccount)","SQLSSIS-$($ServiceAccount)","SQLSSAS-$($ServiceAccount)","SQLSSRS-$($ServiceAccount)"
$groupsqlNameArray = "$authaccessgroup"

foreach ($usersql in $gmsaNameArray) {
  foreach ($groupsqlName in $groupsqlNameArray) {
    $sqlAccountDn = (Get-ADServiceAccount -Server $DomainDnsRoot -Identity $userSql -Properties PrincipalsAllowedToRetrieveManagedPassword).DistinguishedName
    Add-ADGroupMember -Server $DomainDnsRoot -Identity $groupsqlName -Members $sqlAccountDn
    Write-Output "$usersql added to $groupsqlName."
  }
}