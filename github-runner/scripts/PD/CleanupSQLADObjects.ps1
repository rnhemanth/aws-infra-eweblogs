param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
  [Parameter(Mandatory=$true)]
  [string]$namePrefix,
  [Parameter(Mandatory=$true)]
  [string]$fullDomain
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

$computerArray = "DBS01","DBS02","RS-01","-CLS","-AG1","-AG2"

foreach ($computer in $computerArray) {
  $computerName = "$($namePrefix)$($pdNumber)$($computer)"

  Write-Host "Removing computer $($computerName)"
  $computerObject = Get-ADComputer -Filter "Name -like '${computerName}'"
  if ($computerObject -ne $null) {
    $computerObject | Remove-ADComputer -Confirm:$False
  }

  Write-Host "Removing DNS records for $($computerName)"
  Get-DnsServerResourceRecord -ComputerName $fullDomain -ZoneName $fullDomain -Name $computerName | Remove-DnsServerResourceRecord -Force -ComputerName $fullDomain -ZoneName $fullDomain
}
