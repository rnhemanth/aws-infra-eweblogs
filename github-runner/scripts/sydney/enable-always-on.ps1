[CmdletBinding()]
param (
    $server,
    $instance
)

Import-Module SqlServer;

Set-Location SQLSERVER:\SQL\$server\$instance;

start-sleep -Seconds 10
Enable-SqlAlwaysOn -Force -NoServiceRestart;
start-sleep -Seconds 30
Get-Service -Name "MSSQL$*" | Restart-Service -Force

start-sleep -Seconds 30
try {
    $pendpoint = New-SqlHADREndPoint -Name 'HADR_endpoint';
    Set-SqlHadrEndpoint -InputObject $pendpoint -State Started;
} catch {
    Write-Host "Database mirroring endpoint already exists"
}
