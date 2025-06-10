[CmdletBinding()]
Param(
    $PDOU,
    $domain,
    $authdbaccessaccount,
    $sqlserviceaccount,
    $sqlagentaccount,
    $sqlbrowseraccount,
    $sqlcuversion,
    $server,
    $instance,
    $buildaction_username,
    $environment_type,
    $default_secret_name
)
#Get domain secret
#$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $default_secret_name).SecretString
$FetchedDefault = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $default_secret_name | ConvertFrom-Json).SecretString

$ADForest = (Get-ADDomain -Identity $FetchedDefault.domain).DNSRoot
$ADDomain = $FetchedDefault.domain
$env_id = "$($environment_type)".ToLower()
$AdminAccounts = @("emis-admin",
    "$ADDomain\backup-user",
    "$ADDomain\$env_id-auth-app",
    "$ADDomain\$env_id-auth-db",
    "$ADDomain\$env_id-sql-admin")
$config = @{
ADDCURRENTUSERASSQLADMIN="False"
AGTSVCSTARTUPTYPE="Automatic"
BROWSERSVCSTARTUPTYPE="Automatic"
FTSVCACCOUNT="NT AUTHORITY\LOCAL SERVICE"
INSTALLSHAREDDIR="C:\Program Files\Microsoft SQL Server"
INSTALLSHAREDWOWDIR="C:\Program Files (x86)\Microsoft SQL Server"
INSTANCEDIR="Q:\\"
NPENABLED="1"
SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"
SQLMAXDOP="1"
SQLTEMPDBDIR="T:\TempDB"
SQLTEMPDBFILECOUNT="1"
SQLTEMPDBFILESIZE="4096"
SQLTEMPDBLOGDIR="T:\TempDB"
SQLTEMPDBLOGFILESIZE="4096"
SQLUSERDBDIR="D:\Databases"
SQLUSERDBLOGDIR="L:\Logs"
ERRORREPORTING="False"
SQMREPORTING="False"
}
$SqlInstallerPath = "D:\SQLInstallers\SQL\"
$CuInstallerPath = "D:\SQLInstallers\CU\"
Write-Host "`nSql instance to be installed is $server`n"
Import-Module dbatools -erroraction SilentlyContinue
Write-Host "Install SQL server, this may take some time. If this is a re-run, you may see errors if SQL server installed already, this is normal"
Install-DbaInstance -Version 2019 -SqlInstance "$server.$ADDomain\$instance" -Feature Engine,FullText -AdminAccount $AdminAccounts -Configuration $config -Path $SqlInstallerPath -Confirm:$false -Restart  

#Start DBAService after all jobs are complete
Get-DBaService -ComputerName "$server.$ADDomain" | Start-DbaService -Confirm:$false

#Update cu version
Get-DbaBuildReference -Update
Update-DbaInstance -ComputerName "$server.$ADDomain" -KB $sqlcuversion -Restart -Path $CuInstallerPath -Confirm:$false
Get-DBaService -ComputerName "$server.$ADDomain" | Start-DbaService -Confirm:$false

#Set static port
Set-DbaNetworkConfiguration -SqlInstance "$server.$ADDomain\$instance" -StaticPortForIPAll 1433 -RestartService -Confirm:$false

Write-Host "Rebooting"
Restart-Computer -ComputerName "$server.$ADDomain" -Force -Wait

start-sleep -Seconds 30

# Force the service to recognise the service account as gMSA
$script = {
  Param(
    $serviceName,
    $Account
  )
  # update the service account name for the SQL service
  $Service = Get-WmiObject Win32_Service -Filter "Name='$serviceName'"
  $Service.Change($null,$null,$null,$null,$null,$null,$Account,$null,$null,$null,$null)
  start-sleep -Seconds 2

  # force gMSA recognition, then restart service
  cmd.exe /c "sc managedaccount $($serviceName) TRUE"
  $check = (cmd.exe /c "sc qmanagedaccount $($serviceName)")
  Write-Host $check

  Restart-Service -Force -Name $serviceName
}

Write-Host "updating services to use gMSA"
# Update services to use gMSA
$ServiceNameMSSQL = 'MSSQL$'+$instance
Invoke-Command -ComputerName "$server.$ADDomain" -ScriptBlock $script -ArgumentList $ServiceNameMSSQL, $sqlserviceaccount

$ServiceNameSQLAgent = 'SQLAgent$'+$instance
Invoke-Command -ComputerName "$server.$ADDomain" -ScriptBlock $script -ArgumentList $ServiceNameSQLAgent, $sqlagentaccount

$ServiceNameSQLBrowser = 'SQLBrowser'
Invoke-Command -ComputerName "$server.$ADDomain" -ScriptBlock $script -ArgumentList $ServiceNameSQLBrowser, $sqlbrowseraccount