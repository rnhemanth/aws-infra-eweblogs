param (
    [Parameter(Mandatory = $true)]
    [string]$certName,
    [Parameter(Mandatory = $true)]
    [string]$certPwd,
    [Parameter(Mandatory = $true)]
    [string]$pd,
    [Parameter(Mandatory = $true)]
    [string]$s3BucketName,
    [Parameter(Mandatory = $true)]
    [string]$certKey,
    [Parameter(Mandatory = $true)]
    [string]$domainpasswordsecretid,
    [Parameter(Mandatory = $true)]
    [String]$adminpasswordid,
    [Parameter(Mandatory = $true)]
    [string]$nameprefix,
    [Parameter(Mandatory = $true)]
    [string]$targetfilter
)

# Retrieve domain admin password from Secret Manager
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value --secret-id $adminpasswordid| ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

# Retrieve domain details
$DomainName = (Get-ADDomain -Credential $Credentials -Identity $FetchedSecret.domain).DistinguishedName
$DomainNetBios = (Get-ADDomain -Credential $Credentials -Identity $FetchedSecret.domain).NetBIOSName
$DomainDnsRoot = (Get-ADDomain -Credential $Credentials -Identity $FetchedSecret.domain).DNSRoot
$Domain = "OU="+$DomainNetBios+","+$DomainName


# set-item wsman:localhost\client\trustedhosts -value * -Force
# Enable-WSManCredSSP -Role Client -DelegateComputer * -Force

$search = 'name -like "'+$nameprefix+$pd+$targetfilter+'"'
$searchBase = 'OU=App_Servers,OU='+$pd+',OU=GP,'+$Domain
$comps = Get-ADComputer -Credential $Credentials -Server $DomainDnsRoot -filter $search -SearchBase $searchBase | Select-Object -Property DNSHostName -ExpandProperty DNSHostName

$sessions = New-PSSession -ComputerName $comps -Credential $Credentials
Invoke-Command -Session $sessions -ScriptBlock {
    Write-Output "Enabling Server CredSSP"
    Enable-WSManCredSSP -Role Server -Force | Out-Null
    Write-Output "Allowing TrustedHosts"
    Set-Item WSMan:\localhost\Client\TrustedHosts "*" -Force
}
Remove-PSSession -Session $sessions

# $Session = New-PSSession -ComputerName localhost -Credential $Credentials
# Invoke-Command -Session $Session -ScriptBlock {
#   Write-Output "Enabling Client CredSSP"
#   Enable-WSManCredSSP -Role Client -DelegateComputer * -Force | Out-Null
# }


$ServiceSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value --secret-id $domainpasswordsecretid| ConvertFrom-Json).SecretString
$Serviceusername = $ServiceSecret.shortname+"\EMISWeb-"+$pd.toUpper() 
$ServiceCredentials = (New-Object PSCredential($Serviceusername,(ConvertTo-SecureString $ServiceSecret.password -AsPlainText -Force)))

$CertificatePassword = $certPwd
$path1 = Join-Path 'C:\Emis\emis_certificate_files' $certKey
$CertificatePath = Join-Path $path1 $certName
$sessions = New-PSSession -ComputerName $comps -Credential $ServiceCredentials -Authentication Credssp

Invoke-Command -Session $sessions -ScriptBlock {
    param($CertificatePath, $CertificatePassword, $certName, $s3BucketName, $certKey)
    if (-not([System.IO.Directory]::Exists('c:\emis\emis_certificate_files'))) {
        New-Item -Path 'c:\emis' -Name 'emis_certificate_files' -ItemType 'directory'
    }
    Remove-Item -Path $CertificatePath -Force -Recurse -ErrorAction:SilentlyContinue
    $literalPath = $CertificatePath.Replace($certName, '')
    aws s3 cp s3://$s3BucketName/$certKey/$certName  $literalPath
    $pfxcert = New-Object system.security.cryptography.x509certificates.x509certificate2
    $pfxcert.Import($CertificatePath, $CertificatePassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]'PersistKeySet' -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]'Exportable')
    $store = Get-Item 'Cert:\LocalMachine\My'
    $store.open('MaxAllowed')
    $store.add($pfxcert)
    $store.close()
    Write-Host "Certificate $certName imported to $env:computername"
    Remove-Item -Path $CertificatePath -Force -Recurse -ErrorAction:SilentlyContinue
} -ArgumentList $CertificatePath, $CertificatePassword, $certName, $s3BucketName, $certKey

Remove-PSSession -Session $sessions

  $sessions = New-PSSession -ComputerName $comps -Credential $Credentials
Invoke-Command -Session $sessions -ScriptBlock {
    Write-Output "Disabling Server CredSSP"
    Disable-WSManCredSSP -Role Server
    Write-Output "Removing TrustedHosts"
    Set-Item WSMan:\localhost\Client\TrustedHosts "" -Force
}
Remove-PSSession -Session $sessions

  # # Remove Sessions
  # Write-Output "Removing sessions"
  # Remove-PSSession $Session
