[CmdletBinding()]
param (
    [Parameter(Mandatory,
    ValueFromPipeline)]
    [string[]]$sqlserviceaccount,

    [Parameter(Mandatory,
    ValueFromPipeline)]
    [string[]]$fullDomain,

    [Parameter(Mandatory,
    ValueFromPipeline)]
    [string[]]$prefix
)

Import-Module ActiveDirectory;

Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)RS-01.$($fullDomain):1433", "MSSQLSvc/$($prefix)RS-01.$($fullDomain)", "MSSQLSvc/$($prefix)RS-01.$($fullDomain):$($prefix)RS"}
Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)DBS01.$($fullDomain):1433", "MSSQLSvc/$($prefix)DBS01.$($fullDomain)", "MSSQLSvc/$($prefix)DBS01.$($fullDomain):$($prefix)DB"}
Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)DBS02.$($fullDomain):1433", "MSSQLSvc/$($prefix)DBS02.$($fullDomain)", "MSSQLSvc/$($prefix)DBS02.$($fullDomain):$($prefix)DB"}
Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)-AG1.$($fullDomain):1433", "MSSQLSvc/$($prefix)-AG1.$($fullDomain):$($prefix)DB"}
Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)-AG2.$($fullDomain):1433", "MSSQLSvc/$($prefix)-AG2.$($fullDomain):$($prefix)DB"}
