[CmdletBinding()]
Param(
    $domain,
    $authdbaccessaccount,
    $sqlserviceaccount,
    $sqlagentaccount,
    $sqlbrowseraccount,
    $sqlcuversion,
    $server,
    $instance,
    $buildaction_username
)

#Set-ADAccountControl -Identity "CN=$server,OU=DB_Servers,OU=LAD,OU=EMISDEVENG,DC=dev,DC=england,DC=emis-web,DC=com" -TrustedForDelegation $True
#Invoke-GPUpdate -Computer $server -Force
#Start-Sleep -Seconds 300

#$ADForest = Get-ADDomain | select -ExpandProperty DNSRoot
$ADDomain = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select-Object Domain -ExpandProperty Domain
$AdminAccounts = @("emis-admin",
    "$ADDomain\lad-sql-admin","$authdbaccessaccount")
$config = @{
ADDCURRENTUSERASSQLADMIN="False"
AGTSVCSTARTUPTYPE="Automatic"
BROWSERSVCSTARTUPTYPE="Automatic"
FTSVCACCOUNT="NT AUTHORITY\LOCAL SERVICE"
INSTALLSHAREDDIR="C:\Program Files\Microsoft SQL Server"
INSTALLSHAREDWOWDIR="C:\Program Files (x86)\Microsoft SQL Server"
INSTALLSQLDATADIR="D:\Databases"
NPENABLED="1"
SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"
SQLMAXDOP="1"
SQLTEMPDBDIR="D:\Databases\TempDB"
SQLTEMPDBFILECOUNT="1"
SQLTEMPDBFILESIZE="4096"
SQLTEMPDBLOGDIR="L:\Logs\TempDB"
SQLTEMPDBLOGFILESIZE="4096"
SQLUSERDBDIR="D:\Databases"
SQLUSERDBLOGDIR="L:\Logs"
}
$SqlInstallerPath = "D:\SQLInstallers\SQL"
$CuInstallerPath = "D:\SQLInstallers\CU\"
Write-Host "`nSql instance to be installed is $instance`n"
Import-Module dbatools -erroraction SilentlyContinue
$sqlcheckfailed=0
try
  {
    $SqlCatalog = "master"
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server = $server; Database = $SqlCatalog; Integrated Security = True; Connection Timeout=1"
    $SqlConnection.Open()
}
catch
  {
    $sqlcheckfailed=1
    Write-Host "Install SQL server, this may take some time. If this is a re-run, you may see errors if SQL server installed already, this is normal"
    Install-DbaInstance -Version 2019 -SqlInstance "$server\$instance" -Feature Engine,FullText -AdminAccount $AdminAccounts -Configuration $config -Path $SqlInstallerPath -Confirm:$false -Restart -EnableException    
}
If (!$sqlcheckfailed) 
  { 
    Write-Host "SQL already installed"
    $SqlConnection.Close()
}

#Start DBAService after all jobs are complete
Get-DBaService -ComputerName $server | Start-DbaService -Confirm:$false

#Update cu version
Get-DbaBuildReference -Update
Update-DbaInstance -ComputerName $server -KB $sqlcuversion -Restart -Path $CuInstallerPath -Confirm:$false
Get-DBaService -ComputerName $server | Start-DbaService -Confirm:$false

#Set static port
Set-DbaNetworkConfiguration -SqlInstance "$server\$instance" -StaticPortForIPAll 1433 -RestartService -Confirm:$false

Write-Host "Rebooting"
Restart-Computer -ComputerName $server -Force -Wait

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
Write-Host "`nArgumentList for MSSQL service is $ServiceNameMSSQL, $sqlserviceaccount`n"
Invoke-Command -ComputerName $server -ScriptBlock $script -ArgumentList $ServiceNameMSSQL, $sqlserviceaccount

$ServiceNameSQLAgent = 'SQLAgent$'+$instance
Invoke-Command -ComputerName $server -ScriptBlock $script -ArgumentList $ServiceNameSQLAgent, $sqlagentaccount

$ServiceNameSQLBrowser = 'SQLBrowser'
Invoke-Command -ComputerName $server -ScriptBlock $script -ArgumentList $ServiceNameSQLBrowser, $sqlbrowseraccount
