[CmdletBinding()]
param (
    $DBS1,
    $DBS2,
    $AG1,
    $AG2,
    $primary_cluster_ip,
    $secondary_cluster_ip,
    $AG1subnet1aIP,
    $AG1subnet1bIP,
    $AG2subnet1aIP,
    $AG2subnet1bIP

)

#Timeout settings
Write-Host "Setting timeout settings"
Get-ClusterResource | where {$_.ResourceType -eq "SQL Server Availability Group"} | Set-ClusterParameter LeaseTimeOut 20000
Get-ClusterResource | where {$_.ResourceType -eq "SQL Server Availability Group"} | Set-ClusterParameter HealthCheckTimeOut 30000

#Network settings
Write-Host "Setting network settings"
(Get-Cluster).SameSubnetThreshold = 25
(Get-Cluster).SameSubnetDelay = 2000
(Get-Cluster).CrossSubnetThreshold = 25
(Get-Cluster).CrossSubnetDelay = 2000
(Get-Cluster).RouteHistoryLength = 20
(Get-Cluster).PlumbAllCrossSubnetRoutes=2

#Set AG1 to high priority, no failback
Write-Host "Setting AG1 priority settings"
$AG1obj = Get-ClusterGroup $AG1
$AG1obj.Priority = 3000
$AG1obj.AutoFailbackType = 0

#Set no failback on AG2
Write-Host "Setting AG2 failback settings"
$AG2obj = Get-ClusterGroup $AG2
$AG2obj.AutoFailbackType = 0

#Set AG Role prefered owners
Write-Host "Setting AG role owner settings"
Set-ClusterOwnerNode -Group $AG1 -Owners $DBS1,$DBS2
Set-ClusterOwnerNode -Group $AG2 -Owners $DBS1,$DBS2

#Set Cluster Resource possible owners
Write-Host "Setting cluster resource owner settings"
Get-ClusterResource "Cluster Name" | Set-ClusterOwnerNode -Owners $DBS1,$DBS2
Get-ClusterResource | Where-Object { $_.Name.Contains("Cluster IP Address") } | Where-Object {$_ | Get-ClusterParameter -Name "Address" | Where-Object {$_.Value -eq "$primary_cluster_ip"}} | Set-ClusterOwnerNode -Owners $DBS1
Get-ClusterResource | Where-Object { $_.Name.Contains("Cluster IP Address") } | Where-Object {$_ | Get-ClusterParameter -Name "Address" | Where-Object {$_.Value -eq "$secondary_cluster_ip"}} | Set-ClusterOwnerNode -Owners $DBS2

#Set AG Resource possible owners
Write-Host "Setting AG resource owner settings"
Get-ClusterResource "$AG1" | Set-ClusterOwnerNode -Owners $DBS1,$DBS2
Get-ClusterResource "$AG2" | Set-ClusterOwnerNode -Owners $DBS1,$DBS2

#Set AG Listener Resource possible owners
Write-Host "Setting AG listener owners settings"
Get-ClusterResource ("$AG1" + "_" + "$AG1") | Set-ClusterOwnerNode -Owners $DBS1,$DBS2
Get-ClusterResource ("$AG2" + "_" + "$AG2") | Set-ClusterOwnerNode -Owners $DBS1,$DBS2

#Set AG Listener IP Resource possible owners
Write-Host "Setting AG listener IP owner settings"
Get-ClusterResource ("$AG1" + "_" + "$AG1subnet1aIP") | Set-ClusterOwnerNode -Owners $DBS1
Get-ClusterResource ("$AG1" + "_" + "$AG1subnet1bIP") | Set-ClusterOwnerNode -Owners $DBS2
Get-ClusterResource ("$AG2" + "_" + "$AG2subnet1aIP") | Set-ClusterOwnerNode -Owners $DBS1
Get-ClusterResource ("$AG2" + "_" + "$AG2subnet1bIP") | Set-ClusterOwnerNode -Owners $DBS2
