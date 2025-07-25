########################################################################
# Script: SQL_PostConfig
# Platform: Windows Server 2019
# Details: Set SQL Instance Max Memory, Run PDAuth, Enable CLR
#
# Ver  Date      Who               Details
# ---  --------  ----------------  ------------------------------------
# 1.0  10-07-12  Mark Howis        Created for EMISWeb SQL Build
# 1.1  18/01/22  Craig Middlemas   Edited for EMISWeb SQL 2019 Build
# 1.2  23/11/11  Glen Harding      Modified for AWS SQL cluster build pipeline
########################################################################

[CmdletBinding()]
param (
    $DB_server,
    $Domain,
	$PDNum
)

#SQL Scripts to run
$script_path = '.\scripts\PD'
$Output_Script = @("SQL_Read_User_$PDNum.sql")

function CreatePDAuthAccess ($PDNUM) {
    Write-Host "`nCreating AuthDBAccess file for $PDNUM`n"
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
        $Srv = New-Object Microsoft.SqlServer.Management.Smo.Server("$DB_server\$Instance")

        #Enable CLR something to do with .NET
        if ($srv.configuration.issqlclrenabled.ConfigValue -eq 1) {
            Write-Host "$instance : CLR Enabled"
        }
        else {
            Write-Host "$instance : Enabling CLR"
            $Srv.configuration.issqlclrenabled.ConfigValue = "1"
            $Srv.alter()
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
if ($MSQLInstances) {CreatePDAuthAccess $PDNum}
if ($MSQLInstances) {RunSQLScripts $MSQLInstances $Output_Script}
