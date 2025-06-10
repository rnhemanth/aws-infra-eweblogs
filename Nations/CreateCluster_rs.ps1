param (
  [Parameter(Mandatory=$true)]
  [string]$node1,
  [Parameter(Mandatory=$true)]
  [string]$node2,
  [Parameter(Mandatory=$true)]
  [string]$node3,
  [Parameter(Mandatory=$true)]
  [string]$clusterName,
  [Parameter(Mandatory=$true)]
  [string]$domainName,
  [Parameter(Mandatory=$true)]
  [string]$primaryClusterIp,
  [Parameter(Mandatory=$true)]
  [string]$secondaryClusterIp,
  [Parameter(Mandatory=$true)]
  [string]$replicaClusterIp,
  [Parameter(Mandatory=$true)]
  [string]$SecretArn
)

# Retrieve domain admin password from Secret Manager
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $SecretArn | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot


Write-Host "Adding build-automation to AWS Delegated Administrators"
Add-ADGroupMember -Identity "AWS Delegated Administrators" -Server $DomainDnsRoot -Members "build-automation" -Credential $Credentials

try {
    # Import-Module FailoverClusters
    if ((Get-Cluster -Domain $domainName).name -eq $clusterName) {
      Write-Host "Cluster $($clusterName) already exists"
    } else {
      New-Cluster -Name $clusterName -Node $node1, $node2, $node3 -NoStorage -AdministrativeAccessPoint ActiveDirectoryAndDNS -StaticAddress $primaryClusterIp, $secondaryClusterIp, $replicaClusterIp
    }
}
catch {
  Write-Output "`n An error occurred during cluster creation. `n $_"
  exit
}
finally {
  Write-Host "Removing build-automation from AWS Delegated Administrators"
  Remove-ADGroupMember -Identity "AWS Delegated Administrators" -Server $DomainDnsRoot -Members "build-automation" -Credential $Credentials -confirm:$false
}