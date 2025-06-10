param (
  [Parameter(Mandatory=$true)]
  [string]$OU,
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

Set-ADAccountControl -Identity "CN=$InstanceHostname,$OU" -TrustedForDelegation $True

(Get-ADDomainController -Filter *).Name | Foreach-Object {repadmin /syncall $_ (Get-ADDomain).DistinguishedName /e /A | Out-Null} 
Start-Sleep 10

Invoke-GPUpdate -Computer $InstanceHostname -RandomDelayInMinutes 0 -Force
