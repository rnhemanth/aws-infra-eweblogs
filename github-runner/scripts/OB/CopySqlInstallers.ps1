[CmdletBinding()]
Param(
    $s3Bucket,
    $sqlPath,
    $cuPath
)

# get the installer files from S3
$Destination_path = "D:\SQLInstallers"
New-Item -Path "$($Destination_path)\SQL" -Type Directory -Force
New-Item -Path "$($Destination_path)\CU" -Type Directory -Force

Write-Host "Copying SQL installers to $($Destination_path)\SQL"
Read-S3Object -BucketName $s3Bucket -KeyPrefix "$($sqlPath)" -Folder "$($Destination_path)\SQL"

Write-Host "Copying SQL CU to $($Destination_path)\CU"
Read-S3Object -BucketName $s3Bucket -KeyPrefix "$($cuPath)" -Folder "$($Destination_path)\CU"