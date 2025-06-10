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
    [string]$AdminSecretName
)

Import-Module ActiveDirectory;

# Retrieve default secret from Secret Manager
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $AdminSecretName | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

# Retrieve domain details
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot

Set-ADServiceAccount -Credential $Credentials -Server $DomainDnsRoot -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)DBS01.$($fullDomain):1433", "MSSQLSvc/$($prefix)DBS01.$($fullDomain)", "MSSQLSvc/$($prefix)DBS01.$($fullDomain):$($prefix)DB"}
Set-ADServiceAccount -Credential $Credentials -Server $DomainDnsRoot -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)DBS02.$($fullDomain):1433", "MSSQLSvc/$($prefix)DBS02.$($fullDomain)", "MSSQLSvc/$($prefix)DBS02.$($fullDomain):$($prefix)DB"}
Set-ADServiceAccount -Credential $Credentials -Server $DomainDnsRoot -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)-AG1.$($fullDomain):1433", "MSSQLSvc/$($prefix)-AG1.$($fullDomain):$($prefix)DB"}
Set-ADServiceAccount -Credential $Credentials -Server $DomainDnsRoot -Identity "$sqlserviceaccount" -ServicePrincipalNames @{Add="MSSQLSvc/$($prefix)-AG2.$($fullDomain):1433", "MSSQLSvc/$($prefix)-AG2.$($fullDomain):$($prefix)DB"}
