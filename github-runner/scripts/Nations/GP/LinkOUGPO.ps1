param (
  [Parameter(Mandatory=$true)]
  [string]$pdNumber,
  [Parameter(Mandatory=$true)]
  # [string]$DefaultSecretName,
  # [Parameter(Mandatory=$true)]
  [string]$EnvironmentType,
  [Parameter(Mandatory=$true)]
  [string]$SecretArn
)

# Import ActiveDirectory module
try {
  Import-Module -Name ActiveDirectory -ErrorAction Stop
} catch {
  if ((Get-WindowsFeature RSAT-DNS-Server).installed -ne 'True') {
    try {
      Install-WindowsFeature -Name GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server -ErrorAction Stop
      Import-Module -Name ActiveDirectory -ErrorAction Stop
    } catch {
      Write-Error "Failed to install ActiveDirectory module. $_"
      exit
    }
  } else {
    Write-Error "Failed to import ActiveDirectory module. $_"
    exit
  }
}

# Retrieve domain admin password from Secret Manager
#$FetchedSecret = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $SecretArn).SecretString
$FetchedSecret = ConvertFrom-Json -InputObject (aws secretsmanager get-secret-value --secret-id $SecretArn | ConvertFrom-Json).SecretString
$username = $FetchedSecret.shortname+"\"+$FetchedSecret.username
$Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))

# Retrieve domain details
$DomainName = (Get-ADDomain -Identity $FetchedSecret.domain).DistinguishedName
$DomainNetBios = (Get-ADDomain -Identity $FetchedSecret.domain).NetBIOSName
$DomainDnsRoot = (Get-ADDomain -Identity $FetchedSecret.domain).DNSRoot
$Domain = "OU="+$DomainNetBios+","+$DomainName

if ([string]::IsNullOrEmpty($DomainNetBios)) {
  Write-Error "Failed to retrieve domain details. Script cannot proceed."
  exit
}


Write-Host "Adding build-automation to AWS Delegated Administrators"
Add-ADGroupMember -Identity "AWS Delegated Administrators" -Server $DomainDnsRoot -Members "build-automation" -Credential $Credentials

try {
    # App OU GP links
    $appOu = "OU=App_Servers,OU="+$pdNumber+",OU=GP,"+$Domain
    $appGpoArray = "gp-app-settings","app-firewall-policy"

    $appLinks = (Get-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -filter "distinguishedName -eq '$appOU'" | Get-GPInheritance -Domain $DomainDnsRoot).GpoLinks.DisplayName

    foreach ($appGpo in $appGpoArray) {
      if ($appLinks -contains $appGpo) {
        Write-Host "$($appGpo) is already linked to the app servers OU."
      } else {
        Write-Host "$($appGpo) is not linked to the app servers OU. `n"
        New-GPLink -Server $DomainDnsRoot -Name $appGpo -Target $appOu
        Write-Output "GP-Link created. GPO = $($appGpo); Path = $appOu `n"
      }
    }

    # DB OU GP links
    $dbOu = "OU=DB_Servers,OU="+$pdNumber+",OU=GP,"+$Domain
    $dbGpoArray = "gp-db-settings","db-firewall-policy"
    
    $dbLinks = (Get-ADOrganizationalUnit -Credential $Credentials -Server $DomainDnsRoot -filter "distinguishedName -eq '$dbOu'" | Get-GPInheritance -Domain $DomainDnsRoot).GpoLinks.DisplayName

    foreach ($dbGpo in $dbGpoArray) {
      if ($dbLinks -contains $dbGpo) {
        Write-Host "$($dbGpo) is already linked to the db servers OU."
      } else {
        Write-Host "$($dbGpo) is not linked to the db servers OU. `n"
        New-GPLink -Server $DomainDnsRoot -Name $dbGpo -Target $dbOu
        Write-Output "GP-Link created. GPO = $($dbGpo); Path = $dbOu `n"
      }
    }
}
catch {
  Write-Output "`n An error occurred!! `n"
  exit
}
finally {
  Write-Host "Removing build-automation from AWS Delegated Administrators"
  Remove-ADGroupMember -Identity "AWS Delegated Administrators" -Server $DomainDnsRoot -Members "build-automation" -Credential $Credentials -confirm:$false
}