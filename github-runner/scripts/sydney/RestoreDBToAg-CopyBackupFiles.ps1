[CmdletBinding()]
Param(
    $s3Bucket,
    $s3Path
)

# get the backup files from S3
$backup_path = "D:\Backups"
New-Item -Path "$($backup_path)\$($s3Path)" -Type Directory -Force

Write-Host "Blank"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/Blank.bak" -File "$($backup_path)\$($s3Path)\Blank.bak"