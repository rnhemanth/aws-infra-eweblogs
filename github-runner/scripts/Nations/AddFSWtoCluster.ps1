param (
  [string]$clusterName,
  [Parameter(Mandatory=$true)]
  [string]$domainName,
  [Parameter(Mandatory=$true)]
  [string]$SecretArn,
  [Parameter(Mandatory=$true)]
  [string]$country,
  [Parameter(Mandatory=$true)]
  [string]$witness,
  [Parameter(Mandatory=$true)]
  [string]$pd
)

# Retrieve domain admin password from Secret Manager
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $SecretArn | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot


Write-Host "Adding build-automation to AWS Delegated Administrators"
Add-ADGroupMember -Identity "AWS Delegated Administrators" -Server $DomainDnsRoot -Members "build-automation" -Credential $Credentials

try {
  if ((Get-Cluster -Domain $domainName -Name $clusterName | Get-ClusterQuorum).QuorumResource) {
    Write-Host "Quorum exists, not recreating"
    } else {
      $ShareName = "AWS_$($country)_$($pd)"
      Get-Cluster -Domain $domainName -Name $clusterName | Set-ClusterQuorum -Credential $Credentials -NodeAndFileShareMajority "\\$($witness)\share\$($ShareName)"
      }
}
catch {
  Write-Output "`n An error occurred during FSW creation. `n $_"
  exit
}
finally {
  Write-Host "Removing build-automation from AWS Delegated Administrators"
  Remove-ADGroupMember -Identity "AWS Delegated Administrators" -Server $DomainDnsRoot -Members "build-automation" -Credential $Credentials -confirm:$false
}