[CmdletBinding()]
Param(
    $s3Path,
    $rs01SqlInstance,
    $pdNumber
)

$backup_path = "D:\Backups"
# restore databases


if (!$(Get-DbaDatabase -SqlInstance $rs01SqlInstance -Database "MKBRuntime")) {
    Restore-DbaDatabase -SqlInstance $rs01SqlInstance -Path "$($backup_path)\$($s3Path)\MKBRuntime.bak" -Database "MKBRuntime" -WithReplace -DestinationDataDirectory "D:\Databases" -DestinationLogDirectory "L:\Logs"
}
