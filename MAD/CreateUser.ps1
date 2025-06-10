param (
  [Parameter(Mandatory=$true)]
  [string]$CsvFilePath,
  [Parameter(Mandatory=$true)]
  [string]$DefaultSecretArn,
  [Parameter(Mandatory=$true)]
  [string]$SecretArn
)

$features = ("RSAT-AD-PowerShell","RSAT-AD-AdminCenter","RSAT-ADDS-Tools","GPMC","RSAT-DNS-Server")
foreach ($feature in $features) {
  if ((Get-WindowsFeature $feature).installed -ne 'True') {
    try {
      Write-Output "Installing feature $feature"
      Install-WindowsFeature -Name $feature -ErrorAction Stop
    }
    catch {
      Write-Error "Failed to install feature $_"
      exit
    }
  }
  if ((Get-Module -Name ActiveDirectory -ListAvailable).Name -eq $null) {
    try {
      Write-Output "Importing module ActiveDirectory"
      Import-Module -Name ActiveDirectory -ErrorAction Stop
    }
    catch { Write-Error "Failed to import ActiveDirectory module. $_" }
  }
}

Write-Output "All modules and features present."

# Retrieve domain admin password from Secret Manager
#$FetchedSecret = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $SecretArn).SecretString
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value --secret-id $SecretArn | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

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

# Retrieve domain details
$DomainName = (Get-ADDomain -Identity $FetchedSecret.domain).DistinguishedName
$DomainNetBios = (Get-ADDomain -Identity $FetchedSecret.domain).NetBIOSName
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot
$Domain = "OU="+$DomainNetBios+","+$DomainName

if ([string]::IsNullOrEmpty($DomainNetBios)) {
  Write-Error "Failed to retrieve domain details. Script cannot proceed."
  exit
}

# Retrieve default password from Secret Manager
#$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $DefaultSecretArn).SecretString
$FetchedDefault = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value --secret-id $DefaultSecretArn | ConvertFrom-Json).SecretString

# Import CSV file containing list of users to create
$CsvFile = $CsvFilePath+"ADUser.csv"
$users = Import-Csv $CsvFile

# Fetch default password from Secret
$Password = (ConvertTo-SecureString $FetchedDefault.password -AsPlainText -Force)

# Loop through each user in the CSV file
foreach ($user in $users) {
  # Build the user's distinguished name based on the provided OU path or the default domain
  if ($user.OU -eq "" -or $user.OU -eq $null) {
    $checkUser = "CN="+$user.Name+","+$Domain
  }
  else {
    $checkUser = "CN="+$user.Name+","+$user.OU+","+$Domain
  }

  # Check if the user already exists by querying for their name using their SamAccountName
  if (Get-ADUser -Server $DomainDnsRoot -Filter "SamAccountName -eq '$($user.Name)'") {
    # User already exists, display their information
    # Write-Output "`n"
    Write-Output "$($user.Name) already exists."
    # Get-ADUser -Server $DomainDnsRoot -Identity $user.Name
  }
  else {
    # User does not exist, so create them
    if ($user.OU -eq "" -or $user.OU -eq $null) {
      $path = $Domain
    } else {
      $path = $user.OU+","+$Domain
    }
    New-ADUser -Credential $Credentials -Server $DomainDnsRoot -Name $user.Name -GivenName $user.Name -SamAccountName $user.Name -Description $user.Description -Enabled $true -AccountPassword $password -Path $path -PasswordNeverExpires $true

    # Output confirmation of user creation
    # Write-Output "`n"
    Write-Output "$($user.Name) created."
    Get-ADUser -Server $DomainDnsRoot -Identity $user.Name
  }
}

# Loop through each user
foreach ($user in $users) {
  $userinfo = (Get-ADUser -Server $DomainDnsRoot -Identity $user.Name)
    # Check if accidental deletion protection is already enabled
    if (!$userinfo.ProtectedFromAccidentalDeletion) {
      # Enable accidental deletion protection
      Set-ADObject -Credential $Credentials -Server $DomainDnsRoot -Identity $userinfo.DistinguishedName -ProtectedFromAccidentalDeletion $true
      Write-Host "Accidental deletion protection enabled for $($user.Name)."
    }
}

# Setting Admin password never expires
Set-ADUser -Credential $Credentials -Server $DomainDnsRoot -Identity $((Get-ADUser -Server $DomainDnsRoot -Filter "SamAccountName -eq 'Admin'").DistinguishedName) -PasswordNeverExpires $true
Write-Host "Admin PasswordNeverExpires set."