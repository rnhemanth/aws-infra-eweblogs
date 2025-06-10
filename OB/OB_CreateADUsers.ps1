param (
  [Parameter(Mandatory=$true)]
  [string]$DefaultSecretName,
  [Parameter(Mandatory=$true)]
  [string]$OU_Name,
  [Parameter(Mandatory=$true)]
  [string]$OUParent,
  [Parameter(Mandatory=$true)]
  [string]$GroupName,
  [Parameter(Mandatory=$false)]
  [string]$AppServiceName

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

# Retrieve default password from Secret Manager
$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $DefaultSecretName).SecretString
$Password = (ConvertTo-SecureString $FetchedDefault.password -AsPlainText -Force)

# Retrieve domain details
$DomainNetBios = (Get-ADDomain -Identity $FetchedDefault.domain).NetBIOSName
$DomainName = (Get-ADDomain -Identity $FetchedDefault.domain).DistinguishedName
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedDefault.domain).DNSRoot
$Domain = "OU="+$DomainNetBios+","+$DomainName


# Construct account OU
$serviceAccountOU = "OU=Service_Accounts,OU=$OU_Name,OU=$OUParent"
$saPath = $serviceAccountOU+","+$Domain

# Create appservice user
if ($null -ne $AppServiceName) {
  $userNameArray = "$AppServiceName-$OU_Name"

  foreach ($userName in $userNameArray) {
      if (Get-ADUser -Filter "SamAccountName -eq '$($userName)'") {
          Write-Output "$($userName) already exists."
          Get-ADUser -Identity $userName
      } else {
          Write-Host "Creating user $($userName)"
          New-ADUser -Name $userName -GivenName $userName -SamAccountName $userName -Description "Used for $OU_Name services." -Enabled $true -AccountPassword $password -Path $saPath -PasswordNeverExpires $true

          # Output confirmation of user creation
          Write-Output "$($userName) created."
          Get-ADUser -Identity $userName
      }
  }
} else {
  Write-Output "AppServiceName is null. Script will not run."
}

# Create gMSA users
$gmsaNameArray = "SQLService-$OU_Name","SQLAgent-$OU_Name","SQLBrowser-$OU_Name"
$allowedPrincipals = "$GroupName"

foreach ($gmsaName in $gmsaNameArray) {
  # Check if the GMSA already exists in Active Directory
  if (Get-ADServiceAccount -Filter "Name -eq '$($gmsaName)'") {
    # If the GMSA already exists, update its properties
    Write-Output "$($gmsaName) already exists."
    Get-ADServiceAccount -Identity $gmsaName
  }
  else {
    Write-Host "Creating user $($gmsaName)"
    # If the GMSA does not exist, create it
    New-ADServiceAccount -Name $($gmsaName) `
    -DNSHostName "$($gmsaName).$($DomainDnsRoot)" `
    -Description "Used for SQL services." `
    -ManagedPasswordIntervalInDays "42" `
    -PrincipalsAllowedToRetrieveManagedPassword $allowedPrincipals `
    -Path $saPath `
    -Enabled $True `
    -SamAccountName $($gmsaName)
    Write-Output "$($gmsaName) created."
    Get-ADServiceAccount $gmsaName
  }
}
