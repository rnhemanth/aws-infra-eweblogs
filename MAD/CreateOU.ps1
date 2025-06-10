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

# Import CSV file containing list of OUs to create
$CsvFile = $CsvFilePath+"ADOU.csv"
$ous = Import-Csv $CsvFile

# Loop through each OU in the CSV file
foreach ($ou in $ous) {

  # Determine the Distinguished Name of the OU to check if it already exists
  if ($ou.Path -eq "" -or $ou.Path -eq $null) {
    # If the Path is empty or null, assume the OU should be created at the root of the domain
    $checkOU = "OU="+$ou.Name+","+$Domain
  } else {
    # Otherwise, include the Path specified in the CSV file
    $checkOU = "OU="+$ou.Name+","+$ou.Path+","+$Domain
  }
  
  # Check if the OU already exists by querying AD for its name
  $OUnames = (Get-ADOrganizationalUnit -Server $DomainDnsRoot -Filter "distinguishedName -eq '$checkOU'").Name

  # If the OU already exists, display a message and retrieve its details
  if ($OUnames -contains $ou.Name) {
    # Write-Output "`n"
    Write-Output "$($ou.Name) already exists."
    # Get-ADOrganizationalUnit -Server $DomainDnsRoot -Filter "distinguishedName -eq '$checkOU'"

  # If the OU does not already exist, create it and display a message
  } else {
    # Determine the Path for the New-ADOrganizationalUnit cmdlet
    if ($ou.Path -eq "" -or $ou.Path -eq $null) {
      # If the Path is empty or null, assume the OU should be created at the root of the domain
      $path = $Domain
    } else {
      # Otherwise, include the Path specified in the CSV file
      $path = $ou.Path+","+$Domain
    }
    # Create the OU and set it to be Protected from Accidental Deletion
    New-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -Name $ou.Name -Path $path -ProtectedFromAccidentalDeletion $True
    # Write-Output "`n"
    Write-Output "$($ou.Name) created."
    Get-ADOrganizationalUnit -Server $DomainDnsRoot -Filter "distinguishedName -eq '$checkOU'"
  }
}

#Update all OU objects to be protected from accidental deletion
Start-Sleep -s 10
Get-ADOrganizationalUnit -Server $DomainDnsRoot -searchbase $Domain -filter * -Properties ProtectedFromAccidentalDeletion | `
where {$_.ProtectedFromAccidentalDeletion -eq $false} | `
Set-ADOrganizationalUnit -Server $DomainDnsRoot -ProtectedFromAccidentalDeletion $true