param (
    [Parameter(Mandatory = $true)]
    [string]$CsvFilePath,
    [Parameter(Mandatory = $true)]
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

# Import the CSV file
$CsvFile = $CsvFilePath+"GroupUsers.csv"
$usersToAdd = Import-Csv -Path $CsvFile

# Loop through each row in the CSV file
foreach ($user in $usersToAdd) {
  # Check if the group exists
  if (Get-ADGroup -Server $DomainDnsRoot -Filter "Name -eq '$($user.GroupName)'") {
    # Check if the user exists
    if ((Get-ADUser -Server $DomainDnsRoot -Filter "SamAccountName -eq '$($user.UserName)'") -or (Get-ADServiceAccount -Server $DomainDnsRoot -Filter "Name -eq '$($user.UserName)'")) {
      if (Get-ADUser -Server $DomainDnsRoot -Filter "SamAccountName -eq '$($user.UserName)'") {
        $dn = (Get-ADUser -Server $DomainDnsRoot -Filter "SamAccountName -eq '$($user.UserName)'").DistinguishedName
      }
      elseif (Get-ADServiceAccount -Server $DomainDnsRoot -Filter "Name -eq '$($user.UserName)'") {
        $dn = (Get-ADServiceAccount -Server $DomainDnsRoot -Filter "Name -eq '$($user.UserName)'").DistinguishedName
      }
      # Check if the user is a member of the group
      $groupMembers = "LDAP://" + (Get-ADGroup -Server $DomainDnsRoot "$($user.GroupName)").DistinguishedName
      $members = ([ADSI]$groupMembers).member | Where-Object { $_ -eq $dn }
      if ($members -eq $dn) {
        Write-Output "$($user.UserName) is already a member of $($user.GroupName)."
      }
      else {
        # If the user is not a member of the group, add the user to the group
        Add-ADGroupMember -Credential $Credentials -Server $DomainDnsRoot -Identity "$($user.GroupName)" -Members "$($dn)"
        Write-Output "$($user.UserName) added to $($user.GroupName)."
      }
    }
    else {
      Write-Host "User $($user.UserName) does not exist."
    }
  }
  else {
    Write-Host "Group $($user.GroupName) does not exist."
  }
}
