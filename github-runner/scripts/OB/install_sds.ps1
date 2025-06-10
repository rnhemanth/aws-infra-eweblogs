[CmdletBinding()]
Param(
    $computerName,
    $Key,
    $ServiceUsername,
    $ServicePassword,
    $ClusterReference,
    $PatchHubAddress,
    $DisableService
)

#$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $DefaultSecretName).SecretString

Invoke-Command -ComputerName $computerName -Script {
    param(
        [string] $Key,
        [string] $ServiceUsername,
        [string] $ServicePassword,
        [string] $ClusterReference,
        [string] $PatchHubAddress,
        [string] $DisableService
    )

    $serviceName = "SDSClientService"
    $isRunning = Get-Service | Where-Object {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}

    if ($isRunning.Status -eq "Running") {
        Write-Host "Running, not re-installing"
    } else {
        Write-Host "Installing EMIS Health Installer"
        Start-Process -FilePath "C:\Agents\EmisHealthInstaller.exe" -ArgumentList "machinetype=emissystem serviceusername=`"$ServiceUsername`" servicepassword=`"$ServicePassword`" clusterreference=`"$ClusterReference`" patchhubaddress=$PatchHubAddress encryptionkey=$Key"
        Start-Sleep -Seconds 240
        $isRunning = Get-Service | Where-Object {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}
        if ($isRunning.Status -eq "Running") {
            Write-Host "SDS Client Service is running"

            if ($DisableService -eq "true") {
                Write-Host "Disabling SDS Client Service until cutover"
                Stop-Service -Name $serviceName
                Set-Service -Name $serviceName -StartupType Disabled
            }
        } else {
            Write-Error "SDS Service not installed succesfully, please check"
            Exit 1
        }
    }
} -ArgumentList $Key, $ServiceUsername, $ServicePassword, $ClusterReference, $PatchHubAddress, $DisableService