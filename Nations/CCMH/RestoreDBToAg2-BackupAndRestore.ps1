[CmdletBinding()]
Param(
    $s3Path,
    $primarySqlServer,
    $secondarySqlServer,
    $pdNumber,
    $AG1name,
    $AG2name
)

$backup_path = "D:\Backups"
$env_id = $primarySqlServer.Substring(0,2)
# restore databases
if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISExternalMessaging")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISExternalMessaging.bak" -Database "EMISExternalMessaging" -WithReplace -DestinationDataDirectory "F:\Databases" -DestinationLogDirectory "F:\Logs"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISExternalMessaging" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
    Backup-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISExternalMessaging" -FilePath NUL -Type Full
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISMonitoring")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISMonitoring.bak" -Database "EMISMonitoring" -WithReplace -DestinationDataDirectory "E:\Databases" -DestinationLogDirectory "E:\Logs"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISMonitoring" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
    Backup-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISMonitoring" -FilePath NUL -Type Full
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISScheduler")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISScheduler.bak" -Database "EMISScheduler" -WithReplace -DestinationDataDirectory "E:\Databases" -DestinationLogDirectory "E:\Logs"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISScheduler" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
    Backup-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISScheduler" -FilePath NUL -Type Full
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISEmail")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISEmail.bak" -Database "EMISEmail" -WithReplace -DestinationDataDirectory "D:\Databases" -DestinationLogDirectory "L:\Logs"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISEmail" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
    Backup-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISEmail" -FilePath NUL -Type Full
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebCRTest_$($env_id)_$($pdNumber)")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISWebCRTest.bak" -Database "EMISWebCRTest_$($env_id)_$($pdNumber)" -WithReplace -DestinationDataDirectory "D:\Databases" -DestinationLogDirectory "L:\Logs"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebCRTest_$($env_id)_$($pdNumber)" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
    Backup-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebCRTest_$($env_id)_$($pdNumber)" -FilePath NUL -Type Full
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISState")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISState.bak" -Database "EMISState" -WithReplace -DestinationDataDirectory "D:\Databases" -DestinationLogDirectory "L:\Logs"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISState" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
    Backup-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISState" -FilePath NUL -Type Full
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebDocTest_$($env_id)_$($pdNumber)")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISWebDocTest.bak" -Database "EMISWebDocTest_$($env_id)_$($pdNumber)" -WithReplace -DestinationDataDirectory "M:\Databases" -DestinationLogDirectory "M:\Logs"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebDocTest_$($env_id)_$($pdNumber)" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
    Backup-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebDocTest_$($env_id)_$($pdNumber)" -FilePath NUL -Type Full
}

# restore MKBRuntime on DBS01 and DBS02
if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "MKBRuntime")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\MKBRuntime.bak" -Database "MKBRuntime" -WithReplace -DestinationDataDirectory "D:\Databases" -DestinationLogDirectory "L:\Logs"
}

if (!$(Get-DbaDatabase -SqlInstance $secondarySqlServer -Database "MKBRuntime")) {
    Restore-DbaDatabase -SqlInstance $secondarySqlServer -Path "$($backup_path)\$($s3Path)\MKBRuntime.bak" -Database "MKBRuntime" -WithReplace -DestinationDataDirectory "D:\Databases" -DestinationLogDirectory "L:\Logs"
}


# Add DB to availability groups
Add-DbaAgDatabase -SqlInstance $primarySqlServer -AvailabilityGroup "$($AG2name)" -Database "EMISExternalMessaging", "EMISMonitoring",  "EMISScheduler", "EMISEmail", "EMISWebDocTest_$($env_id)_$($pdNumber)" -SeedingMode Automatic -EnableException
Get-DbaAgReplica -SqlInstance $primarySqlServer -AvailabilityGroup "$($AG2name)"
Add-DbaAgDatabase -SqlInstance $primarySqlServer -AvailabilityGroup "$($AG1name)" -Database "EMISWebCRTest_$($env_id)_$($pdNumber)", "EMISState"
Get-DbaAgReplica -SqlInstance $primarySqlServer -AvailabilityGroup "$($AG1name)"
