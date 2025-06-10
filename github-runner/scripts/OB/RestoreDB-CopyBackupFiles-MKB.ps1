[CmdletBinding()]
Param(
    $s3Bucket,
    $s3Path
)

# download the backup files from S3
$backup_path = "D:\Backups"
New-Item -Path "$($backup_path)\$($s3Path)" -Type Directory -Force

Write-Host "MKBRuntime"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/MKBRuntime.bak" -File "$($backup_path)\$($s3Path)\MKBRuntime.bak"