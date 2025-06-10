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
    [string[]]$prefix,

    [Parameter(Mandatory,
    ValueFromPipeline)]
    [string[]]$agname
)

Import-Module ActiveDirectory;

Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)DBS01.$($fullDomain):1433", "MSSQLSvc/$($prefix)DBS01:1433", "MSSQLSvc/$($prefix)DBS01.$($fullDomain)", "MSSQLSvc/$($prefix)DBS01"}
Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)DBS02.$($fullDomain):1433", "MSSQLSvc/$($prefix)DBS02:1433", "MSSQLSvc/$($prefix)DBS02.$($fullDomain)", "MSSQLSvc/$($prefix)DBS02"}
Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($agname).$($fullDomain):1433", "MSSQLSvc/$($agname):1433", "MSSQLSvc/$($agname).$($fullDomain)", "MSSQLSvc/$($agname)"}