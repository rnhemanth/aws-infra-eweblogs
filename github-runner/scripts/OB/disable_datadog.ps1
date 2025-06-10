[CmdletBinding()]
Param(
    $computerName
)

Invoke-Command -ComputerName $computerName -Script {

    $serviceName = "datadogagent"
    $dd = Get-Service | Where-Object {($_.Name -like $serviceName)}

    if ($dd)
    {
        if ($dd.Status -eq "Running") {
            Write-Host "Disabling DataDog service"
            Stop-Service -Name $serviceName -Force
        }
        else {
            Write-Host "DataDog Service already stopped"
        }

        if ($dd.StartType -ne "Disabled") {
            Set-Service -Name $serviceName -StartupType Disabled
        }
        else {
            Write-Host "DataDog Service already disabled"
        }
    }
    else {
        Write-Error "DataDog Service not installed!"
    }
}