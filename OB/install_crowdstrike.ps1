[CmdletBinding()]
Param(
    $computerName,
    $InstallSource,
    $CID,
    $Environment,
    $ServerType,
    $PDNumber
)

Invoke-Command -ComputerName $computerName -Script {
    param(
        [string] $InstallSource,
        [string] $CID,
        [string] $Environment,
        [string] $ServerType,
        [string] $PDNumber
    )

    $serviceName = "CSFalconService"
    $isRunning = Get-Service | where {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}

    # if falcon service is running, don't re-install
    if ($isRunning.Status -eq "Running") {
        Write-Host "Running, not re-installing"
    } else {
        Write-Host ("Disable Windows Defender")

        if ( !(Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue ) -eq 1 ) {
        Set-MpPreference -DisableRealtimeMonitoring $true
        }

        if ( !(Test-Path "HKLM:\Software\Policies\Microsoft\Windows Defender") ) {
        New-Item -Path "HKLM:\Software\Policies\Microsoft" -Name "Windows Defender"
        }
        if ( !(Test-Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection") ) {
        New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows Defender" -Name "Real-Time Protection"
        }
        if ( !(Get-ItemPropertyValue -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue ) -eq 1 ) {
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value "1"
        }
        $GroupingTags="AWS_Hosted,$($Environment),EM,EMISWeb-LAD,EMISWeb-$($ServerType)"
        Write-Host ("Installing Crowdstrike from path: {0} with Grouping Tags: {1}" -f $InstallSource, $GroupingTags)
        Start-Process -FilePath $InstallSource "/install /quiet /norestart CID=$CID GROUPING_TAGS=""$($GroupingTags)"" PACURL=""https://pac.zscaler.net/2gtP52yPD7YZ/EMIS-AWS-PAC""" -Wait

        # check that the falcon service is running after install, exit if it isn't
        $isRunning = Get-Service | where {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}
        if ($isRunning.Status -eq "Running") {
            Write-Host "Falcon service is running"
        } else {
            Write-Host "Retrying Installation of Crowdstrike"
            Start-Sleep -Seconds 10
            Start-Process -FilePath $InstallSource "/install /quiet /norestart CID=$CID GROUPING_TAGS=""$($GroupingTags)"" PACURL=""https://pac.zscaler.net/2gtP52yPD7YZ/EMIS-AWS-PAC""" -Wait
            $isRunning = Get-Service | where {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}
            if ($isRunning.Status -eq "Running") {
               Write-Host "Falcon service is running"
            } else {
                Write-Error "Falcon service is not running, please check"
                Exit 1
            }
        }
    }

} -ArgumentList $InstallSource, $CID, $Environment, $ServerType, $PDNumber
