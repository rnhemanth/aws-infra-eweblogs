param (
  [Parameter(Mandatory=$true)]
  [string]$CsvFilePath,
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

# Import the CSV file containing the GMSA data
$CsvFile = $CsvFilePath+"ADGMSA.csv"
$gmsas = Import-Csv $CsvFile

# Loop through each GMSA in the CSV file
foreach ($gmsa in $gmsas) {
  # Determine the distinguished name of the GMSA
  if ($gmsa.Path -eq "" -or $gmsa.Path -eq $null) {
    # If the GMSA path is empty or null, use the default domain path
    $checkGMSA = "CN="+$gmsa.Name+","+$Domain
  } else {
    # Otherwise, use the provided GMSA path
    $checkGMSA = "CN="+$gmsa.Name+","+$gmsa.Path+","+$Domain
  }

  # Check if the GMSA already exists in Active Directory
  if (Get-ADServiceAccount -Server $DomainDnsRoot -Filter "Name -eq '$($gmsa.Name)'") {
    # If the GMSA already exists, update its properties
    # Write-Output "`n"
    Write-Output "$($gmsa.Name) already exists."
    # Get-ADServiceAccount -Server $DomainDnsRoot -Identity $gmsa.Name
  }
  else {
    # If the GMSA does not exist, create it
    New-ADServiceAccount -Credential $Credentials -Server $DomainDnsRoot -Name $gmsa.Name `
    -DNSHostName "$($gmsa.Name).$($DomainDnsRoot)" `
    -Description $gmsa.Description `
    -ManagedPasswordIntervalInDays $gmsa.PasswordInterval `
    -PrincipalsAllowedToRetrieveManagedPassword $gmsa.PrincipalsAllowed `
    -Path "$($gmsa.Path),$($Domain)" `
    -Enabled $True
    # Write-Output "`n"
    Write-Output "$($gmsa.Name) created."
    Get-ADServiceAccount -Server $DomainDnsRoot -Identity $gmsa.Name
  }
}

# Loop through each GMSA
foreach ($gmsa in $gmsas) {
  $gmsainfo = (Get-ADServiceAccount -Server $DomainDnsRoot -Identity $gmsa.Name)
  # Check if accidental deletion protection is already enabled
  if (!$gmsainfo.ProtectedFromAccidentalDeletion) {
    # Enable accidental deletion protection
    Set-ADObject -Credential $Credentials -Server $DomainDnsRoot -Identity $gmsainfo.DistinguishedName -ProtectedFromAccidentalDeletion $true
    Write-Host "Accidental deletion protection enabled for $($gmsa.Name)."
  }
}
