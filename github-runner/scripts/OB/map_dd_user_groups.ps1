param (
  [Parameter(Mandatory=$true)]
  [string]$ad_group_name
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

# Update dd-agent-user GMSA
$ad_group_name = $ad_group_name.ToLower()
$ddAgentName = "dd-agent-user"

# construct details of allowed principals
$ddGmsaInfo = (Get-ADServiceAccount -Identity $ddAgentName -Properties PrincipalsAllowedToRetrieveManagedPassword)
# add comma separated computer groups (e.g. "bastion-computers","wsus-computers")
$allowedPrincipals = "$($ad_group_name)"
foreach ($allowedPrincipal in $allowedPrincipals) {
    [array]$allowedPrincipalsDn += (Get-ADGroup -Filter "Name -eq '$($allowedPrincipal)'").DistinguishedName
}
[array]$arrGetMgdPasswd = ($ddGmsaInfo).PrincipalsAllowedToRetrieveManagedPassword

# if the allowed principal isn't already in the allowed list, add it
foreach ($dn in $allowedPrincipalsDn) {
  if ($dn -in $arrGetMgdPasswd) {
    Write-Host "NO UPDATE NEEDED: $($dn) is already in the list of allowed principals for $($ddAgentName)"
  } else {
    Write-Host "Adding $($dn) to the list of allowed principals for $($ddAgentName)"
    $arrGetMgdPasswd += $dn
    Set-ADServiceAccount -Identity $ddAgentName -PrincipalsAllowedToRetrieveManagedPassword $arrGetMgdPasswd
  }
}
