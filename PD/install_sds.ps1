[CmdletBinding()]
Param(
    $computerName,
    $Key,
    $ServiceUsername,
    $DefaultSecretName,
    $ClusterReference,
    $PatchHubAddress
)

$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $DefaultSecretName).SecretString

Invoke-Command -ComputerName $computerName -Script {
    param(
        [string] $Key,
        [string] $ServiceUsername,
        [string] $ServicePassword,
        [string] $ClusterReference,
        [string] $PatchHubAddress
    )

    $serviceName = "SDSClientService"
    $isRunning = Get-Service | where {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}

    if ($isRunning.Status -eq "Running") {
        Write-Host "Running, not re-installing"
    } else {
        Write-Host "Installing EMIS Health Installer"
        Start-Process -FilePath "C:\Agents\EmisHealthInstaller.exe" -ArgumentList "serviceusername=$ServiceUsername servicepassword=$ServicePassword clusterreference=$ClusterReference patchhubaddress=$PatchHubAddress encryptionkey=$Key"
        Start-Sleep -Seconds 240
        $isRunning = Get-Service | where {($_.Name -like $serviceName)-and ($_.Status -eq "Running")}
        if ($isRunning.Status -eq "Running") {
            Write-Host "SDS Client Service is running"
        } else {
            Write-Error "SDS Client Service is not running, please check"
            Exit 1
        }
    }
} -ArgumentList $Key, $ServiceUsername, $FetchedDefault.password, $ClusterReference, $PatchHubAddress
