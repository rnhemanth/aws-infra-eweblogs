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

# Import CSV file containing list of groups to create
$CsvFile = $CsvFilePath+"ADGroup.csv"
$groups = Import-Csv $CsvFile

# Loop through each group in the CSV file
foreach ($group in $groups) {

  # If the group doesn't have a path specified, use the default domain path
  if ($group.Path -eq "" -or $group.Path -eq $null) {
    $checkGroup = "CN="+$group.Name+","+$Domain
  } else {
    $checkGroup = "CN="+$group.Name+","+$group.Path+","+$Domain
  }

  # Check if the group already exists in Active Directory
  if (Get-ADGroup -Server $DomainDnsRoot  -Filter "Name -eq '$($group.Name)'") {
    # Write-Output "`n"
    Write-Output "$($group.Name) already exists."
    # Get-ADGroup -Server $DomainDnsRoot -Identity $group.Name
  }
  else {
    # If the group doesn't exist, create it
    if ($group.Path -eq "" -or $group.Path -eq $null) {
      $path = $Domain
    } else {
      $path = $group.Path+","+$Domain
    }
    New-ADGroup -Credential $Credentials -Server $DomainDnsRoot -Name $group.Name -SamAccountName $group.Name -GroupCategory $group.Category -GroupScope $group.Scope -DisplayName $group.Name -Path $path -Description $group.Description
    # Write-Output "`n"
    Write-Output "$($group.Name) created."
    Get-ADGroup -Server $DomainDnsRoot -Identity $group.Name
  }
}

# Loop through each group
foreach ($group in $groups) {
  $groupinfo = (Get-ADGroup -Server $DomainDnsRoot -Identity $group.Name)
    # Check if accidental deletion protection is already enabled
    if (!$groupinfo.ProtectedFromAccidentalDeletion) {
        # Enable accidental deletion protection
        Set-ADObject -Credential $Credentials -Server $DomainDnsRoot -Identity $groupinfo.DistinguishedName -ProtectedFromAccidentalDeletion $true
        Write-Host "Accidental deletion protection enabled for $($group.Name)."
    }
}
