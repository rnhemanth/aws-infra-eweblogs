param (
  [Parameter(Mandatory=$true)]
  [string]$SecretArn,
  [Parameter(Mandatory=$true)]
  [string[]]$computer_groups
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

if ([string]::IsNullOrEmpty($computer_groups)) {
  Write-Host "No computer groups provided, nothing to do."
}
else {
  # Update dd-agent-user GMSA
  $ddAgentPath = "OU=Service_Accounts,OU=Users,"+$Domain
  $ddAgentName = "dd-agent-user"

  # construct details of allowed principals
  $ddGmsaInfo = (Get-ADServiceAccount -Server $DomainDnsRoot -Identity $ddAgentName -Properties PrincipalsAllowedToRetrieveManagedPassword)
  # add comma separated computer groups (e.g. "bastion-computers","wsus-computers")
  $allowedPrincipals = $computer_groups
  foreach ($allowedPrincipal in $allowedPrincipals) {
      [array]$allowedPrincipalsDn += (Get-ADGroup -Server $DomainDnsRoot -Filter "Name -eq '$($allowedPrincipal)'").DistinguishedName
  }
  [array]$arrGetMgdPasswd = ($ddGmsaInfo).PrincipalsAllowedToRetrieveManagedPassword

  # if the allowed principal isn't already in the allowed list, add it
  foreach ($dn in $allowedPrincipalsDn) {
    if ($dn -in $arrGetMgdPasswd) {
      Write-Host "NO UPDATE NEEDED: $($dn) is already in the list of allowed principals for $($ddAgentName)"
    } else {
      Write-Host "Adding $($dn) to the list of allowed principals for $($ddAgentName)"
      $arrGetMgdPasswd += $dn
      Set-ADServiceAccount -Credential $Credentials -Server $DomainDnsRoot -Identity $ddAgentName -PrincipalsAllowedToRetrieveManagedPassword $arrGetMgdPasswd
    }
  }
}