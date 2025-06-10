param (
  [Parameter(Mandatory=$true)]
  [string]$CsvFilePath,
  [Parameter(Mandatory=$true)]
  [string]$SecretArn,
  [Parameter(Mandatory=$true)]
  [string]$GpoBakupZipFile,
  [Parameter(Mandatory=$true)]
  [string]$GpoMigrationTable,
  [Parameter(Mandatory=$true)]
  [string]$PasswordPolicyGroup
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

# Create backup folder on D drive
$FolderName = "D:\AD\backup"
if (-not(Test-Path $FolderName)) {
    New-Item -ItemType Directory -Path $FolderName -Force
}
else {
  Write-Output "$FolderName already exists."
}

if (Test-Path -Path $GpoBakupZipFile -PathType Leaf) {
   $GpoBackupFile=(Get-Item -Path $GpoBakupZipFile).Basename
   $GpoBackup=$FolderName+"\"+$GpoBackupFile
   Expand-Archive -Path $GpoBakupZipFile -DestinationPath $GpoBackup -Force -ErrorAction Stop
   Get-ChildItem -Path $GpoBackup
} else {
    Write-Output "$GpoBakupZipFile does not exist."
    exit
}

$CsvFile = $CsvFilePath+"ADGPO.csv"
$GPOs = Import-Csv $CsvFile

# $Session = New-PSSession -ComputerName localhost -Credential $Credentials
# Invoke-Command -Session $Session -ScriptBlock {
#   Write-Output "Enabling Client CredSSP"
#   Enable-WSManCredSSP -Role Client -DelegateComputer * -Force | Out-Null
# }
# Invoke-Command -Session $Session -ScriptBlock {
#   Write-Output "Enabling Server CredSSP"
#   Enable-WSManCredSSP -Role Server -Force | Out-Null
# }
# Invoke-Command -Session $Session -ScriptBlock {
#   if ((Get-Item WSMan:\localhost\Client\TrustedHosts).Value -ne "*") {
#     Write-Output "Allowing TrustedHosts"
#     Set-Item WSMan:\localhost\Client\TrustedHosts "*" -Force
#   }
# }

# $CredSSPSession = New-PSSession -ComputerName localhost -Credential $Credentials -Authentication CredSSP

try {
  # Invoke-Command -Session $CredSSPSession -ArgumentList @($DomainDnsRoot,$Domain,$Credentials,$GpoMigrationTable,$GpoBackup,$GPOs) {
  #   param ($DomainDnsRoot,$Domain,$Credentials,$GpoMigrationTable,$GpoBackup,$GPOs)
    Write-Host "Importing GPOs..."
    foreach ($GPO in $GPOs) {
      $BackupPath=$GpoBackup+"\"+$GPO.Name
      $MigrationTable=$GpoBackup+"\"+$GpoMigrationTable
      $GpoBackupPath=$(Split-Path -Path $(Get-ChildItem -Path $BackupPath -Directory | Select-Object -ExpandProperty FullName) -Parent)
      $GpoMigrationTablePath=$(Get-ChildItem -Path $MigrationTable -Directory | Select-Object -ExpandProperty FullName)
      Import-GPO -Domain $DomainDnsRoot -Server $DomainDnsRoot -BackupGpoName $GPO.Name -TargetName $GPO.Name -Path $GpoBackupPath -MigrationTable $GpoMigrationTablePath -CreateIfNeeded | Out-Null
      Write-Output "Import $($GPO.Name) completed."
    }
    foreach ($GPO in $GPOs) {
      if ($GPO.Path -eq "None") {
        Write-Output "GPO Link for $($GPO.Name) not set up during bootstrap."
      }
      else {
        if ($GPO.Path -eq "" -or $GPO.Path -eq $null) {
          $Path = $Domain
        }
        else {
          $Path = $GPO.Path+","+$Domain
        }
        $CheckLink = $((Get-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -filter * | Get-GPInheritance).GpoLinks | Select-Object -Property Target,DisplayName,Enabled,Enforced,Order | Where-Object {$_.DisplayName -eq $GPO.Name}).Target

        if ( $CheckLink -eq $Path) {
          Write-Output "GPO Link already exists for $($GPO.Name). `n GPO = $($GPO.Name); Path = $Path"
        }
        else {
          New-GPLink -Server $DomainDnsRoot -Name $GPO.Name -Target $Path -LinkEnabled Yes
          Write-Output "GPO Link created for $($GPO.Name). `n GPO = $($GPO.Name); Path = $Path"
          #Get-GPO -Server $DomainDnsRoot -Name $GPO.Name | Select DisplayName,GpoStatus,Id,ModificationTime
        }
      }
    }
  #End Invoke Command
  # }
}
catch {
  Write-Output "`n An error occurred during GPO Import. `n $_"
  exit
}
# finally {
#   Invoke-Command -Session $Session -ScriptBlock {
#     Write-Output "Disabling Server CredSSP"
#     Disable-WSManCredSSP -Role Server
#   }
#   Invoke-Command -Session $Session -ScriptBlock {
#     Write-Output "Removing TrustedHosts"
#     Set-Item WSMan:\localhost\Client\TrustedHosts "" -Force
#   }

#   # Remove Sessions
#   Write-Output "Removing sessions"
#   Remove-PSSession $CredSSPSession
#   Remove-PSSession $Session
# }

Write-Output "Updating Fine grained password policy."

Set-ADFineGrainedPasswordPolicy -Credential $Credentials -Server $DomainDnsRoot -Identity "CustomerPSO-01" -ComplexityEnabled $true `
  -Description "fine-grained password policy" -LockoutDuration "0.00:30:00" -LockoutObservationWindow "0.00:30:00" `
  -LockoutThreshold 4 -MaxPasswordAge "42.00:00:00" -MinPasswordAge "1.00:00:00" `
  -MinPasswordLength 16 -PasswordHistoryCount 8 -ReversibleEncryptionEnabled $false

Write-Output "Fine grained password policy created."

if (Get-ADGroup -Server $DomainDnsRoot -Filter "Name -eq '$PasswordPolicyGroup'") {
  Add-ADFineGrainedPasswordPolicySubject -Credential $Credentials -Server $DomainDnsRoot -Identity "CustomerPSO-01" -Subjects $PasswordPolicyGroup
  Write-Output "Fine grained password policy applied to $PasswordPolicyGroup"
}

# The below needs to move to ADMGMT userdata
# $DestinationPathAdml = "C:\Windows\PolicyDefinitions\en-US"
# $DestinationPathAdmx = "C:\Windows\PolicyDefinitions"

# Copy-Item -Credential $Credentials "$GpoBackup\msedge.adml" $DestinationPathAdml -Force
# Copy-Item -Credential $Credentials "$GpoBackup\msedge.admx" $DestinationPathAdmx -Force
# Write-Output "msedge files copied to PolicyDefinitions"