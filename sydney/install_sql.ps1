[CmdletBinding()]
Param(
    $domain,
    $sqlserviceaccount,
    $sqlagentaccount,
    $sqlbrowseraccount,
    $sqlcuversion,
    $server,
    $instance,
    $authdbaccessaccount,
    $dbaadmin
)

$ADForest = Get-ADDomain | select -ExpandProperty DNSRoot
$ADDomain = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain -ExpandProperty Domain
$AdminAccounts = @("emis-admin",
    "$ADDomain\backup-user",
    "$ADDomain\nbu-sql-admin",
    "$ADDomain\nbu-auth-db",
    "$($authdbaccessaccount)",
    "$($dbaadmin)")
$config = @{
ADDCURRENTUSERASSQLADMIN="False"
AGTSVCSTARTUPTYPE="Automatic"
BROWSERSVCSTARTUPTYPE="Automatic"
FTSVCACCOUNT="NT AUTHORITY\LOCAL SERVICE"
INSTALLSHAREDDIR="C:\Program Files\Microsoft SQL Server"
INSTALLSHAREDWOWDIR="C:\Program Files (x86)\Microsoft SQL Server"
INSTANCEDIR="Q:\\"
NPENABLED="1"
SQLCOLLATION="Latin1_General_CI_AS"
SQLMAXDOP="1"
SQLTEMPDBDIR="T:\TempDB"
SQLTEMPDBFILECOUNT="4"
SQLTEMPDBFILESIZE="4096"
SQLTEMPDBLOGDIR="T:\TempDB"
SQLTEMPDBLOGFILESIZE="4096"
SQLUSERDBDIR="D:\Databases"
SQLUSERDBLOGDIR="L:\Logs"
}

Import-Module dbatools -erroraction SilentlyContinue
Write-Host "Install SQL server, this may take some time. If this is a re-run, you may see errors if SQL server installed already, this is normal"
Install-DbaInstance -Version 2019 -SqlInstance "$server\$instance" -Feature Engine,FullText -AdminAccount $AdminAccounts -Configuration $config -Path "C:\Agents\SQL_2019_ENT\" -Confirm:$false -Restart

#Start DBAService after all jobs are complete
Get-DBaService -ComputerName $server | Start-DbaService -Confirm:$false

#Update cu version
Get-DbaBuildReference -Update
Update-DbaInstance -ComputerName $server -KB $sqlcuversion -Restart -Path "C:\Agents\SQL_2019_Cumulative_Update_23\" -Confirm:$false
Get-DBaService -ComputerName $server | Start-DbaService -Confirm:$false

#Set static port
Set-DbaNetworkConfiguration -SqlInstance "$server\$instance" -StaticPortForIPAll 1433 -RestartService -Confirm:$false

Write-Host "Rebooting"
Restart-Computer -ComputerName $server -Force -Wait

start-sleep -Seconds 60

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
Invoke-Command -ComputerName $server -ScriptBlock $script -ArgumentList $ServiceNameMSSQL, $sqlserviceaccount

$ServiceNameSQLAgent = 'SQLAgent$'+$instance
Invoke-Command -ComputerName $server -ScriptBlock $script -ArgumentList $ServiceNameSQLAgent, $sqlagentaccount

$ServiceNameSQLBrowser = 'SQLBrowser'
Invoke-Command -ComputerName $server -ScriptBlock $script -ArgumentList $ServiceNameSQLBrowser, $sqlbrowseraccount
