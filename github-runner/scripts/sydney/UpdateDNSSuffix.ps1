[CmdletBinding()]
Param(
  $Domain
)

$existingSearchList = (Get-DnsClientGlobalSetting).SuffixSearchList

If ($existingSearchList -notcontains $Domain) {
    Write-Host "Adding $($Domain) to list of domain suffixes"
    $existingSearchList += $Domain
    Set-DnsClientGlobalSetting -SuffixSearchList $existingSearchList
} else {
    Write-Host "Domain suffix already exists"
}
