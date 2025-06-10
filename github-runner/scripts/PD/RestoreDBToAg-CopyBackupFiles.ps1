[CmdletBinding()]
Param(
    $s3Bucket,
    $s3Path
)

# get the backup files from S3
$backup_path = "D:\Backups"
New-Item -Path "$($backup_path)\$($s3Path)" -Type Directory -Force

Write-Host "EMISExternalMessaging"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISExternalMessaging.bak" -File "$($backup_path)\$($s3Path)\EMISExternalMessaging.bak"

Write-Host "EMISMonitoring"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISMonitoring.bak" -File "$($backup_path)\$($s3Path)\EMISMonitoring.bak"

Write-Host "EMISScheduler"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISScheduler.bak" -File "$($backup_path)\$($s3Path)\EMISScheduler.bak"

Write-Host "EMISEmail"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISEmail.bak" -File "$($backup_path)\$($s3Path)\EMISEmail.bak"

Write-Host "EMISWebCRTest"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISWebCRTest.bak" -File "$($backup_path)\$($s3Path)\EMISWebCRTest.bak"

Write-Host "EMISWebDocTest"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISWebDocTest.bak" -File "$($backup_path)\$($s3Path)\EMISWebDocTest.bak"

Write-Host "MKBRuntime"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/MKBRuntime.bak" -File "$($backup_path)\$($s3Path)\MKBRuntime.bak"

Write-Host "EMISState"
# download backup file
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISState.bak" -File "$($backup_path)\$($s3Path)\EMISState.bak"
