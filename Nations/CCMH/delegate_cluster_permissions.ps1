Param(
   [Parameter(Position=1)]
   [string]$OU,

   [Parameter(Position=2)]
   [string]$PDOU,

   [Parameter(Position=3)]
   [string]$ClusterObjectName,

   [Parameter(Position=4)]
   [string]$AdminSecretName
)

Import-Module -Name ActiveDirectory

# Retrieve default secret from Secret Manager
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value  --secret-id $AdminSecretName | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

# Retrieve domain details
$DomainNetBios = (Get-ADDomain -Identity $FetchedSecret.domain).NetBIOSName
$DomainName = (Get-ADDomain -Identity $FetchedSecret.domain).DistinguishedName
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot
$Domain = "OU=CCMH,OU="+$DomainNetBios+","+$DomainName

# $OU = (Get-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -Identity $Domain).DistinguishedName
# Write-Host "OU=$OU `n"

$OrganizationalUnit = "OU=DB_Servers,OU="+$PDOU+","+$Domain
Write-Host $OrganizationalUnit
# $ACL = Get-Acl -Path $OrganizationalUnit

#set location to AD:
Write-Host "Setting Location to AD `n"
try {
    New-PSDrive -Credential $Credentials -Name RemoteAD -PSProvider ActiveDirectory -Server $DomainDnsRoot -Scope Global -root "//RootDSE/"
    Set-Location RemoteAD:
}
catch {
    Write-Host "Unable to set location to AD"
    $Check = 1
    return
}

# Invoke-Command -ComputerName $DomainDnsRoot -Credential $Credentials -ArgumentList @($OU,$PDOU,$Domain,$ClusterObjectName) {
#    param ($OU,$PDOU,$Domain,$ClusterObjectName)
#    Set-Location AD:
#    $OrganizationalUnit = "OU="+$OU+",OU="+$PDOU+","+$Domain
#    Write-Host $OrganizationalUnit
$ACL = Get-Acl -Path $OrganizationalUnit
   
$ComputerName = $ClusterObjectName
$Computer = Get-ADcomputer -Credential $Credentials -Server $DomainDnsRoot -Identity $ComputerName
$ComputerSID = [System.Security.Principal.SecurityIdentifier] $Computer.SID
$Identity = [System.Security.Principal.IdentityReference] $ComputerSID
   
$Type = [System.Security.AccessControl.AccessControlType] "Allow"
$InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
$ADRight = [System.DirectoryServices.ActiveDirectoryRights]  "CreateChild, DeleteChild"
$RuleCreateAndDeleteComputer = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Identity, $ADRight, $Type, $InheritanceType)

$ACL.AddAccessRule($RuleCreateAndDeleteComputer)
Set-Acl -Path $OrganizationalUnit -AclObject $ACL
   # #End Invoke Command
   # }
 
#Delay for permission changes to replicate before trying to use them
Start-Sleep -s 30

 