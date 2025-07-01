[CmdletBinding()]
param (
    [Parameter(Mandatory,
        ValueFromPipeline)]
    [string[]]$fullDomain,

    [Parameter(Mandatory,
        ValueFromPipeline)]
    [string[]]$sqlserviceaccount,

    [Parameter(Mandatory,
        ValueFromPipeline)]
    [string[]]$prefix,

    [Parameter(Mandatory,
        ValueFromPipeline)]
    [string]$AdminSecretName,
    
    [Parameter(Mandatory,
        ValueFromPipeline)]
    [string[]]$serverSuffix
)

Import-Module ActiveDirectory

# Retrieve default secret from Secret Manager
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value --secret-id $AdminSecretName | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname + '\' + $FetchedSecret.username
$Credentials = (New-Object PSCredential($username, (ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

# Retrieve domain details
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot

Set-ADServiceAccount -Credential $Credentials -Server $DomainDnsRoot -Identity "$sqlserviceaccount" -ServicePrincipalNames @{
    Add = "MSSQLSvc/$($prefix)$($serverSuffix).$($fullDomain):1433",
    "MSSQLSvc/$($prefix)$($serverSuffix).$($fullDomain)"
}