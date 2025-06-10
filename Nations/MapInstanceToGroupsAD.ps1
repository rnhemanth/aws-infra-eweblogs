param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
  [Parameter(Mandatory=$true)]
  [string]$InstanceHostname,
  [Parameter(Mandatory=$true)]
  [string]$SecretArn
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
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $SecretArn | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))


# Retrieve domain details
$DomainName = (Get-ADDomain -Identity $FetchedSecret.domain).DistinguishedName
$DomainNetBios = (Get-ADDomain -Identity $FetchedSecret.domain).NetBIOSName
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot
$Domain = "OU="+$DomainNetBios+","+$DomainName

if ([string]::IsNullOrEmpty($DomainNetBios)) {
  Write-Error "Failed to retrieve domain details. Script cannot proceed."
  exit
}

# set group and computer names/dn
$groupName = "$($pdNumber)-db-computers".ToLower()
$computerDn = (Get-ADComputer -Server $DomainDnsRoot -Identity $InstanceHostname).DistinguishedName

if ((Get-ADGroupMember -Server $DomainDnsRoot -Identity $groupName -Recursive | Where-Object {$_.name -eq $InstanceHostname}) -eq $null) {
  # If the user is not a member of the group, add the user to the group
  Add-ADGroupMember -Credential $Credentials -Server $DomainDnsRoot -Identity $groupName -Members $computerDn
  Write-Output "$InstanceHostname added to $groupName."
  Restart-Computer -ComputerName "$InstanceHostname.$DomainDnsRoot" -Force
}
else {
  Write-Output "NO UPDATE NEEDED: $InstanceHostname is already a member of $groupName."
}
