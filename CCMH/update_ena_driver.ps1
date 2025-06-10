[CmdletBinding()]
Param(
    $computerName,
    $ProxyHostname,
    $ProxyPort
)

Invoke-Command -ComputerName $computerName -Script {
    param(

        [string] $ProxyHostname,
        [string] $ProxyPort
    )


Write-Host "Updating Amazon Elastic Network Adapter driver version, current version is:"
Get-WmiObject Win32_PnPSignedDriver| select devicename, driverversion | where {$_.devicename -like "*Amazon Elastic Network Adapter*"}
invoke-webrequest https://ec2-windows-drivers-downloads.s3.amazonaws.com/ENA/Latest/AwsEnaNetworkDriver.zip -outfile C:\Agents\AwsEnaNetworkDriver.zip -Proxy "http://${ProxyHostname}:${ProxyPort}"
expand-archive C:\Agents\AwsEnaNetworkDriver.zip -DestinationPath C:\Agents\AwsEnaNetworkDriver -Force
C:\Agents\AwsEnaNetworkDriver\install.ps1
} -ArgumentList $ProxyHostname, $ProxyPort
