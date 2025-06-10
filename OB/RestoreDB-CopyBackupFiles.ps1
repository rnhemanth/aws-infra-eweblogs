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

Write-Host "EMISExternalMessaging"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISExternalMessaging.bak" -File "$($backup_path)\$($s3Path)\EMISExternalMessaging.bak"

Write-Host "EMISMonitoring"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISMonitoring.bak" -File "$($backup_path)\$($s3Path)\EMISMonitoring.bak"

Write-Host "EMISScheduler"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISScheduler.bak" -File "$($backup_path)\$($s3Path)\EMISScheduler.bak"

Write-Host "EMISEmail"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISEmail.bak" -File "$($backup_path)\$($s3Path)\EMISEmail.bak"

Write-Host "EMISWebCRTest"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISWebCRTest.bak" -File "$($backup_path)\$($s3Path)\EMISWebCRTest.bak"

Write-Host "EMISWebDocTest"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISWebDocTest.bak" -File "$($backup_path)\$($s3Path)\EMISWebDocTest.bak"

Write-Host "EMISState"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISState.bak" -File "$($backup_path)\$($s3Path)\EMISState.bak"

Write-Host "EMISConnectCatalogue"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISConnectCatalogue.bak" -File "$($backup_path)\$($s3Path)\EMISConnectCatalogue.bak"

Write-Host "EMISConnectDistributed"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISConnectDistributed.bak" -File "$($backup_path)\$($s3Path)\EMISConnectDistributed.bak"

Write-Host "EMISConnectMonitoring"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISConnectMonitoring.bak" -File "$($backup_path)\$($s3Path)\EMISConnectMonitoring.bak"

Write-Host "EMISHubMonitoring"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISHubMonitoring.bak" -File "$($backup_path)\$($s3Path)\EMISHubMonitoring.bak"

Write-Host "EMISIdentityMonitoring"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISIdentityMonitoring.bak" -File "$($backup_path)\$($s3Path)\EMISIdentityMonitoring.bak"

Write-Host "EMISIndex"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISIndex.bak" -File "$($backup_path)\$($s3Path)\EMISIndex.bak"

Write-Host "EMISIndexMonitoring"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/EMISIndexMonitoring.bak" -File "$($backup_path)\$($s3Path)\EMISIndexMonitoring.bak"

Write-Host "EMISIdentityServer"
Read-S3Object -BucketName $s3Bucket -Key "$($s3Path)/IdentityServer.bak" -File "$($backup_path)\$($s3Path)\IdentityServer.bak"