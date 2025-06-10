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