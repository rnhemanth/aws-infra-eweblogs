param (
  [Parameter(Mandatory=$true)]
  [string]$node1,
  [Parameter(Mandatory=$true)]
  [string]$node2,
  [Parameter(Mandatory=$true)]
  [string]$clusterName,
  [Parameter(Mandatory=$true)]
  [string]$domainName,
  [Parameter(Mandatory=$true)]
  [string]$primaryClusterIp,
  [Parameter(Mandatory=$true)]
  [string]$secondaryClusterIp
)

Import-Module FailoverClusters

if ((Get-Cluster -Domain $domainName).name -eq $clusterName) {
  Write-Host "Cluster $($clusterName) already exists"
} else {
  New-Cluster -Name $clusterName -Node $node1, $node2 -NoStorage -AdministrativeAccessPoint ActiveDirectoryAndDNS -StaticAddress $primaryClusterIp, $secondaryClusterIp
}
