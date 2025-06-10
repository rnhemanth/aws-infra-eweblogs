param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber
)
# add user SQL Agent service user to Administrators group
$SQLAgentServiceAccount = "SQLAgent-$($pdNumber)$"
if ((Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.name -like "*$($SQLAgentServiceAccount)"}) -eq $null) {
    Add-LocalGroupMember -Group "Administrators" -Member $SQLAgentServiceAccount
    Write-Output "$SQLAgentServiceAccount added to Administrators"
}
else {
  Write-Output "NO UPDATE NEEDED: $SQLAgentServiceAccount is already a member of Administrators."
}
