[CmdletBinding()]
Param(
    $computerName,
    $InstallSource,
    $Key,
    $ProxyHostname,
    $ProxyPort,
    $PDNumber,
    $Country
)

Invoke-Command -ComputerName $computerName -Script {
    param(
        [string] $InstallSource,
        [string] $Key,
        [string] $ProxyHostname,
        [string] $ProxyPort,
        [string] $PDNumber,
        [string] $Country
    )

    $serviceName = "Tenable Nessus Agent"
    $isRunning = Get-Service | where {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}

    # if Tenable Nessus Agent service is running, don't install
    if ($isRunning.Status -eq "Running") {
        Write-Host "Running, not re-installing"
    } else {
        Write-Host ("Installing Nessus from path: {0}" -f $InstallSource)
        Start-Process -FilePath msiexec -ArgumentList "/i $InstallSource NESSUS_OFFLINE_INSTALL='yes' /qn" -Wait
        Start-Sleep 120
        $pdNumberLower = $pdNumber.ToLower()
        $country = $Country.ToLower()
        Start-Process -FilePath "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" -ArgumentList "agent link --cloud --key=$Key --proxy-host=$ProxyHostname --proxy-port=$ProxyPort --groups=aws-$($pdNumberLower)-emisweb-$($pdNumberLower)" -Wait

        # check that the nessus agent service is running after install, exit if it isn't
        $isRunning = Get-Service | where {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}
        if ($isRunning.Status -eq "Running") {
            Write-Host "Tenable Nessus Agent service is running"
        } else {
            Write-Error "Tenable Nessus Agent service is not running, please check"
            Exit 1
        }
    }

} -ArgumentList $InstallSource, $Key, $ProxyHostname, $ProxyPort, $PDNumber, $Country
