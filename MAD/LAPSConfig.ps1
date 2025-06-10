param (
  [Parameter(Mandatory=$true)]
  [string]$SecretArn,
  [Parameter(Mandatory=$true)]
  [string[]]$LAPSOUs
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
  # Invoke-Command -Session $CredSSPSession -ArgumentList @($Domain,$DomainNetBios,$DomainDnsRoot,$LAPSOUs,$Credentials) {
  #   param ($Domain,$DomainNetBios,$DomainDnsRoot,$LAPSOUs,$Credentials)
    $principal = "$DomainNetBios\"+"laps-admins"
    foreach ($OU in $LAPSOUs) {
      $OU_DN = $OU+","+$Domain
      # Add LAPS Permissions
      Write-Host "Adding LAPS permissions on $($OU_DN)"
      Set-LapsADComputerSelfPermission -Identity $OU_DN -Domain $DomainDnsRoot -Credential $Credentials
      Set-LapsADReadPasswordPermission -Identity $OU_DN -AllowedPrincipals $principal -Domain $DomainDnsRoot -Credential $Credentials
    }
  #End Invoke Command
  # }
#End try
}
catch {
  Write-Output "`n An error occurred during LAPS Config. `n $_"
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