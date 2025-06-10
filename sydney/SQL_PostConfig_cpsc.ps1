[CmdletBinding()]
param (
    $DB_server,
    $Domain
)

#SQL Scripts to run
$script_path = '.\scripts\sydney'
$Output_Script = @("SQL_Read_User.sql")

function CreatePDAuthAccess () {
    Write-Host "`nCreating AuthDBAccess file`n"
    $SourceFile = "$script_path\SQL_Read_User_Template.sql"
    $OutFile = "$script_path\$Output_Script"
    if (Test-Path $SourceFile) {
        Get-Content $SourceFile | foreach {$_ -replace 'domain', $domain} | Set-Content $OutFile
    }
    else {
        Write-Warning "Unable to locate template file : $sourcefile"
    }
}

function RunSQLScripts ($MSQLInstances, $SQLScripts) {
    $SourcePath = "$script_path\"
    foreach ($Instance in $MSQLInstances) {
        Write-Host $SQLScripts
        foreach ($SQLScript in $SQLScripts) {
            Write-Host "Running $SourcePath$SQLScript for $Instance"
            invoke-sqlcmd -InputFile ($SourcePath + $SQLScript) -ServerInstance $DB_server\$Instance -OutputSqlErrors $False -TrustServerCertificate
            Remove-Item ($SourcePath + $SQLScript)
        }
    }
}

function Enable_CLR ($MSQLInstances) {
    foreach ($Instance in $MSQLInstances) {
        #Create SQL server object
        $srv = New-Object Microsoft.SqlServer.Management.Smo.Server("$DB_server\$Instance")

        #Enable CLR something to do with .NET
        if ($srv.configuration.issqlclrenabled.ConfigValue -eq 1) {
            Write-Host "$instance : CLR Enabled"
        }
        else {
            Write-Host "$instance : Enabling CLR"
            $srv.configuration.issqlclrenabled.ConfigValue = 1
            $srv.alter()
        }
    }
}

################
# Start Script #
################

Import-module -name SqlServer
#Load SQL WMI Elements
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null


$MSQL = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $DB_server

Write-Host "`nRunning on server $DB_Server"

if (!$?) {Write-Host "SQL not installed on $DB_Server" -foregroundcolor red; Exit 1}
$MSQLInstance = $MSQL.serverinstances | Foreach {$_.name}
Write-Host "SQL Instance(s) Discovered : $MSQLInstance`n"
$MSQLInstances = @()

foreach ($Instance in $MSQLInstance) {
    $a = $MSQL.services | Where {$_.ServiceState -eq "Running" -and $_.displayname -eq "SQL Server ($instance)"}
    if ($a) {$MSQLInstances += $Instance}
}

Write-Host "Running on SQL Instances $MSQLInstances...`r"

#Call functions
if ($MSQLInstances) {Enable_CLR $MSQLInstances}
if ($MSQLInstances) {CreatePDAuthAccess}
if ($MSQLInstances) {RunSQLScripts $MSQLInstances $Output_Script}
