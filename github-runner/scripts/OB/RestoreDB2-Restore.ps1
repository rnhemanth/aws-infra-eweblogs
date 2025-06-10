[CmdletBinding()]
Param(
    $s3Path,
    $primarySqlServer,
    $pdNumber
)

$backup_path = "D:\Backups"
$database_path = "D:\Databases"
$log_path = "L:\Logs"

# restore databases
if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "MKBRuntime")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\MKBRuntime.bak" -Database "MKBRuntime" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISExternalMessaging")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISExternalMessaging.bak" -Database "EMISExternalMessaging" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISExternalMessaging" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebMonitoring")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISMonitoring.bak" -Database "EMISWebMonitoring" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebMonitoring" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISScheduler")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISScheduler.bak" -Database "EMISScheduler" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISScheduler" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISEmail")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISEmail.bak" -Database "EMISEmail" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISEmail" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebCRTest_$($pdNumber)")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISWebCRTest.bak" -Database "EMISWebCRTest_$($pdNumber)" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebCRTest_$($pdNumber)" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISState")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISState.bak" -Database "EMISState" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISState" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebDocTest_$($pdNumber)")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISWebDocTest.bak" -Database "EMISWebDocTest_$($pdNumber)" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISWebDocTest_$($pdNumber)" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISConnectCatalogue")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISConnectCatalogue.bak" -Database "EMISConnectCatalogue" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISConnectCatalogue" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISConnectDistributed")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISConnectDistributed.bak" -Database "EMISConnectDistributed" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISConnectDistributed" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISConnectMonitoring")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISConnectMonitoring.bak" -Database "EMISConnectMonitoring" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)" -DestinationFileSuffix "Connect"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISConnectMonitoring" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISHubMonitoring")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISHubMonitoring.bak" -Database "EMISHubMonitoring" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)" -DestinationFileSuffix "Hub"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISHubMonitoring" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISIdentityMonitoring")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISIdentityMonitoring.bak" -Database "EMISIdentityMonitoring" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)" -DestinationFileSuffix "Identity"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISIdentityMonitoring" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISIndex")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISIndex.bak" -Database "EMISIndex" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISIndex" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISIndexMonitoring")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\EMISIndexMonitoring.bak" -Database "EMISIndexMonitoring" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)" -DestinationFileSuffix "Index"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISIndexMonitoring" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}

if (!$(Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISIdentityServer")) {
    Restore-DbaDatabase -SqlInstance $primarySqlServer -Path "$($backup_path)\$($s3Path)\IdentityServer.bak" -Database "EMISIdentityServer" -WithReplace -DestinationDataDirectory "$($database_path)" -DestinationLogDirectory "$($log_path)"
    Get-DbaDatabase -SqlInstance $primarySqlServer -Database "EMISIdentityServer" | Set-DbaDbRecoveryModel -RecoveryModel Full  -Confirm:$false
}