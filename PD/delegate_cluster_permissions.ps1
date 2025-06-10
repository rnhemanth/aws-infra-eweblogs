Param(
   [Parameter(Position=1)]
   [string]$OU,

   [Parameter(Position=2)]
   [string]$PDOU,

   [Parameter(Position=3)]
   [string]$ClusterObjectName,

   [Parameter(Position=4)]
   [string]$DefaultSecretName
)

Import-Module -Name ActiveDirectory

# Retrieve default secret from Secret Manager
$FetchedDefault = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $DefaultSecretName).SecretString

# Retrieve domain details
$DomainNetBios = (Get-ADDomain -Identity $FetchedDefault.domain).NetBIOSName
$DomainName = (Get-ADDomain -Identity $FetchedDefault.domain).DistinguishedName
$Domain = "OU=GP,OU="+$DomainNetBios+","+$DomainName

Set-Location AD:
$OrganizationalUnit = "OU="+$OU+",OU="+$PDOU+","+$Domain
Write-Host $OrganizationalUnit
$ACL = Get-Acl -Path $OrganizationalUnit

$ComputerName = $ClusterObjectName
$Computer = Get-ADcomputer -Identity $ComputerName
$ComputerSID = [System.Security.Principal.SecurityIdentifier] $Computer.SID
$Identity = [System.Security.Principal.IdentityReference] $ComputerSID

$Type = [System.Security.AccessControl.AccessControlType] "Allow"
$InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
$ADRight = [System.DirectoryServices.ActiveDirectoryRights]  "CreateChild, DeleteChild"
$RuleCreateAndDeleteComputer = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Identity, $ADRight, $Type, $InheritanceType)

$ACL.AddAccessRule($RuleCreateAndDeleteComputer)
Set-Acl -Path $OrganizationalUnit -AclObject $ACL

#Delay for permission changes to replicate before trying to use them
Start-Sleep -s 30
