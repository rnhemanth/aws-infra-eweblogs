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
    [string[]]$computername
)

Import-Module ActiveDirectory;

Set-ADServiceAccount -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($computername).$($fullDomain):1433", "MSSQLSvc/$($computername).$($fullDomain)", "MSSQLSvc/$($computername).$($fullDomain):$($computername)"}
