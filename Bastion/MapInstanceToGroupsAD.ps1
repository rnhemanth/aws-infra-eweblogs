param (
  [Parameter(Mandatory=$true)]
  [string]$group,
  [Parameter(Mandatory=$true)]
  [string]$InstanceHostname
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

# set group and computer names/dn
$groupName = "$($group)".ToLower()
$computerDn = (Get-ADComputer -Identity $InstanceHostname).DistinguishedName

if ((Get-ADGroupMember -Identity $groupName -Recursive | Where-Object {$_.name -eq $InstanceHostname}) -eq $null) {
  # If the user is not a member of the group, add the user to the group
  Add-ADGroupMember -Identity $groupName -Members $computerDn
  Write-Output "$InstanceHostname added to $groupName."
}
else {
  Write-Output "NO UPDATE NEEDED: $InstanceHostname is already a member of $groupName."
}
