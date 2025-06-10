param ($cred)

$ScriptPath = "$(split-path($myinvocation.mycommand.path))"
#$Source = "$($ScriptPath)\Source"

$SourceXMLFile = "$($ScriptPath)\XML\Host-Report.xml" #Live
$SourcePortsXML = "$($ScriptPath)\XML\PortCheck.XML"
$SourceMobileXML = "$($ScriptPath)\XML\Mobile.XML" #Live

$xmlinput = "$SourceXMLFile"
[xml] $XMLFile = new-object System.Xml.XmlDocument #Load XML the .Net class
$XMLFile.load($xmlinput)

$XMLPortFile = "$SourcePortsXML"
[xml] $XMLFilePorts = new-object System.Xml.XmlDocument #Load XML the .Net class
[xml]$XMLFilePorts.load($XMLPortFile)

$XMLMobileFile = "$SourceMobileXml"
[xml] $XMLFileMobile = new-object System.Xml.XmlDocument #Load XML the .Net class
[void]$XMLFileMobile.load($XMLMobileFile)

#param($cred, $XMLFile, $XMLFilePorts, $XMLFileMobile) #, $ExportDrive) #param passed from calling script if 'empty' script will prompt for user


#Write-Host "Remote Script Start!... tester script"

#write-host $cred.username #Output for testing purposes
#Read passed xml file into hash table
$XMLFile.SQL.version | ForEach { $SQLHash = @{} } { $SQLHash += @{$_.name = $_.description} }
#write-host "postXML file"
##$SQLHash

#Write-Output "Test.........."

$HKCR = 2147483648 #HKEY_CLASSES_ROOT
$HKCU = 2147483649 #HKEY_CURRENT_USER
$HKLM = 2147483650 #HKEY_LOCAL_MACHINE
$HKUS = 2147483651 #HKEY_USERS
$HKCC = 2147483653 #HKEY_CURRENT_CONFIG
$reg = [wmiclass]'\\.\root\default:StdRegprov'

#Init Arrays
#Added SDS Services 28/12/2012 - MH
$AllServices = @("RemoteFilerService","Emis.Services.WindowsService","Emis.ExternalMessaging.WindowsCoreService","Emis.Scheduler.WindowsService","Emis.Connect.Core.Host","SDSInstallerService","SDSClientService")
$OSInfo = @()
$NetworkInfo = @()
$VolumeInfo = @()
$ProgramInfo = @()
$SQLInfo = @()
$DataDogServices = @()
$AntiVirus = @()
$MonitoringServices = @()
$SQLServerAccess = @()
$AppServices = @()
$DGInfo = @()
$NetBackupServices = @()
$DiskInfo = @()
$NetTest = @()
$DNSInfo = @()
$RouteInfo = @()
$AppFiles = @()
$ClusterInfo = @()
$DBChecks = @()
$SQLLogins = @()
$MobileTest = @()
$Certificates = @()
$HostFileInfo = @()
$SQLServiceSPNs = @()

#Grab standard values, hostname, Domain, PDNumber
$HName = hostname
$HName = $HName.toupper()
$PDNum = $HName.substring(6,4)
<# #Removed 08-06-2023
$DomainFQDN = (get-wmiobject WIN32_ComputerSystem).Domain
$DomainShort=(([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).name.split(".")[0])
$Domain = $DomainShort.replace($DomainShort, "EMISPRDENG")
#>
# $Domain = "EMISPRDENG"
#$LogonSRV = $env:logonserver -replace "\\", ""

#Write-Host "FQDN: $DomainFQDN"
#Write-Host "Domain: $DomainShort"

#New method to query Domain Name 08-06-2023
$ADSystemInfo = New-Object -ComObject "ADSystemInfo"

# Set the credentials (username and password) for the ADSystemInfo object
$ADSystemInfo.GetType().InvokeMember("Put", "InvokeMethod", $null, $ADSystemInfo, @("SecureReferenceValue", $cred.GetNetworkCredential().username))
$ADSystemInfo.GetType().InvokeMember("Put", "InvokeMethod", $null, $ADSystemInfo, @("SecureReferenceValue", $cred.GetNetworkCredential().password))

$DomainName = $ADSystemInfo.GetType().InvokeMember("DomainShortName", "GetProperty", $null, $ADSystemInfo, $null)
$DomainFQDN = $ADSystemInfo.GetType().InvokeMember("DomainDNSName", "GetProperty", $null, $ADSystemInfo, $null)
$ComputerOU = ($ADSystemInfo.GetType().InvokeMember("ComputerName", "GetProperty", $null, $ADSystemInfo, $null) -split ",",2)[1]


Write-Host "FQDN: $DomainFQDN"
Write-Host "Domain: $DomainName"

#Locate Domain controllers, depending on how script is called
#Attempt to obtain from namespace for active directory first
#If that fails obtain from environment variable
#If that fails perform a DNS srv query
#$DCs = ([System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()).Servers
#Write-Host "Listing DCs V1" $DCs
$DCs = ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).domaincontrollers
#Write-Host "Listing DCs V2" $DCs
If ($DCs) {
	Foreach ($DC in $DCs) {
		#Write-Host $DC
		Write-Host "Testing DC connection"
		#$TestConn = Test-Connection "$DC" -Count 1 -ErrorAction SilentlyContinue #ICMP disabled, needs to check port 53
		$TestConn = Test-NetConnection "$DC" -port 53 -ErrorAction SilentlyContinue #ICMP disabled, needs to check port 53
		If ( $TestConn.TcpTestSucceeded -eq $True ) {$GPLiveDC = $DC.name; break} #Added $null check
		}
	}
If ( $TestConn.TcpTestSucceeded -eq $False ) { #Added $null check
	Write-Host "Listing DCs from DNS"
<# Code replaced with below block 08-06-2023
	$SrvRecs = nslookup -type=all _ldap._tcp.dc._msdcs.$DomainFQDN | Where {$_ -like "*hostname*"} -ErrorAction SilentlyContinue #Added FQDN
	ForEach ($SrvRec in $SrvRecs) {
		$tempDNS = $SrvRec.split("=")
		$DNSDC = $tempDNS[1].trim()
		#$TestConn = Test-Connection "$DNSDC" -Count 1 -ErrorAction SilentlyContinue #ICMP disabled, needs to check port 53
		$TestConn = Test-NetConnection "$DNSDC" -port 53 -ErrorAction SilentlyContinue #ICMP disabled, needs to check port 53
		If ( $TestConn -ne $Null ) {$GPLiveDC = $DNSDC; break}
        Else { Write-Host "No Connection to: $($DNSDC)" }
		}
#>
    #Replacement code 08-06-2023
    $SrvRecs = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$DomainFQDN" -Type SRV
    ForEach ($SrvRec in $SrvRecs) {
	    $TestConn = Test-NetConnection $($SrvRec.NameTarget) -port 53 -ErrorAction SilentlyContinue
        If ( $TestConn.TcpTestSucceeded -eq $True ) {$GPLiveDC = $($SrvRec.NameTarget); break}
        Else { Write-Host "No Connection to: $($SrvRec.NameTarget)" }
		}
	}
ElseIf ( $TestConn.TcpTestSucceeded -eq $False -And $GPLiveDC -eq $Null)  {
	Write-host "DC: Getting Environment Variable"
	$LogonSRV = $env:logonserver -replace "\\", ""
	If ($LogonSRV -ne "") {
		$GPLiveDC = "$LogonSRV.$DomainFQDN" #Added FQDN
		}
	}


#$GPLiveDC = "GPLDC01"
#Write-Host "Domain Controller:: $GPLiveDC"

#Determine service type from hostname
Switch ($HName) {
	{$_ -like "*$PDNUMA" -or $_ -like "*$PDNUMB"} {$Service = "DB Servers"}
	{$_ -like "*$PDNUMDBS*"} {$Service = "DB Servers"}
	{$_ -like "*APP*" -OR $_ -like "*CSE*" -or $_ -like "*EMAS*"} {$Service = "App Servers"}

    # {$_ -match "App01|App02|App03|App07|App08|App09" -and $AppServicesSource.name -eq "Emis.Services.WindowsService" -and $AppServicesSource.name -eq "Emis.Scheduler.WindowsService"} {$Service ="EW-Private"}
    # {$_ -match "App04|App05|App10|App11" -and $AppServicesSource.name -eq "Emis.Services.WindowsService"} {$Service ="EW-Public"}
    # {$_ -match "App06|App12" -and $AppServicesSource.name -eq "Emis.ExternalMessaging.WindowsCoreService"} {$Service ="EMAS"}
}

Write-Host "Server Name : $HName.$DomainFQDN"
Write-Host $Service

#Operating System, Service Pack  from WMI
#$Domain=(([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).name.split(".")[0]).replace($Domain, "EMISPRDENG")
##$Domain = $DomainShort.replace($DomainShort, "EMISPRDENG") #Commented out 08-06-2023
$OSVer = (get-wmiobject win32_operatingsystem).caption
$SPVer = (get-wmiobject win32_operatingsystem).servicepackmajorversion
$Serial = (get-wmiobject win32_BIOS).serialnumber
$TimeZone= (Get-WMIObject Win32_TimeZone).caption
#$Procs = (Get-WmiObject Win32_Processor) #New procs routine 08-06-2023
$Procs = [object[]]$(get-WMIObject Win32_Processor) #New procs routine 08-06-2023
$PageFiles = (Get-WmiObject Win32_PageFileSetting)
$AutoPageFile = (Get-WmiObject Win32_ComputerSystem).AutomaticManagedPageFile
$PowerPlan = (Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power -filter "IsActive = 'True'").Elementname

#Write-Host "Locales"
$Locales = @()
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
IF ($OSVer -match "2012|2016|2019") {$SIDs = ((Get-Item HKU:'\*') | ? {$_.name -notmatch "Classes" -and $_.name -notmatch "Default"}).name}
IF ($OSVer -match "2008") {$SIDs = (Get-Item HKU:'\*') | ? {$_.name -notmatch "Classes" -and $_.name -notmatch "Default"} | % {$_.name}}
ForEach ($Sid in $SIDs) {
	$Path = "\$SID\Control Panel\International\"
	$Locale = Get-ItemProperty HKU:$Path -name Locale | Select Locale
	$User = New-Object System.Security.Principal.SecurityIdentifier(($SID).split("\")[1])
	$UserName = ($USER.Translate([System.Security.Principal.NTAccount])).value
	ForEach ($Loc in $Locale.locale) {
        $FrmLoc = [System.Globalization.CultureInfo]([Convert]::ToInt32($loc,16))
        #Write-Host $FrmLoc
		If ($OSVer -match "2012|2016|2019") {
			$Locales += New-Object -TypeName PSObject  -Property ([ordered]@{
				Sid = $Sid
				User = $UserName
				LocaleName = $FrmLoc
	            LocaleCode = $Loc
				})
			}
		If ($OSVer -match "2008") {
			$Locales += New-Object -TypeName PSObject  -Property @{
				Sid = $Sid
				User = $UserName
				LocaleName = $FrmLoc
	            LocaleCode = $Loc
				}
			}
		}
	}
Remove-PSDrive -Name HKU

$hash = @{
	Label = "Domain Name"
	#Value = (([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).name.split(".")[0]).replace($Domain, "EMISPRDENG")
	#Value = $DomainShort.replace($DomainShort, "EMISPRDENG") #Commented out 08-06-2023
	Value = $DomainName #Added 08-06-2023
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
$hash = @{
	Label = "FQDN"
	#Value = (([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).name.split(".")[0]).replace($Domain, "EMISPRDENG")
	#Value = $DomainShort.replace($DomainShort, "EMISPRDENG") #Commented out 08-06-2023
	Value = $DomainFQDN #Added 08-06-2023
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
$hash = @{
	Label = "OU"
	#Value = (([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).name.split(".")[0]).replace($Domain, "EMISPRDENG")
	#Value = $DomainShort.replace($DomainShort, "EMISPRDENG") #Commented out 08-06-2023
	Value = $ComputerOU #Added 08-06-2023
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
$hash = @{
	Label = "Operating System"
	Value = $OSVer
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
$hash = @{
	Label = "Service Pack Level"
	Value = "Service Pack " +$SPVer
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
$hash = @{
	Label = "Serial Number"
	Value = "$Serial"
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output

<#
$Procs = [object[]]$(get-WMIObject Win32_Processor) #New procs routine 08-06-2023
$OSInfo = @()
$LPCount = 0
ForEach ($Proc in $Procs) {
	$CPUNum = $Proc.DeviceID
	$ProcName = $Proc.Name
	$ProcLPs = $Proc.NumberOfLogicalProcessors
	$hash = @{
		Label = "Processor $CPUNum type"
		Value = "$PRocName"
		}
	$Output = New-Object psobject -Property $hash
	$OSInfo += $Output
	$hash = @{
		Label = "Processor $CPUNum Logical Processor(s)"
		Value = "$PRocLPs"
		}
    $LPCount = $LPCount + $ProcLPs
    $Output = New-Object psobject -Property $hash
	$OSInfo += $Output
	}
$hash = @{
    Label = "Logical Processors (Total)"
    Value = $LPCount
    }
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
#>

ForEach ($Proc in $Procs) {
	$CPU_ID = $Proc.DeviceID
	$ProcName = $Proc.Name
	$ProcLPs = $Proc.NumberOfLogicalProcessors
    $ProcCores = $Proc.NumberOfCores
    $hash = @{
		Label = "Processor $CPU_ID type"
		Value = $($PRocName)
		}
    $Output = New-Object psobject -Property $hash
	$OSInfo += $Output
    $hash = @{
		Label = "Processor $CPU_ID Core(s)"
		Value = $($ProcCores)
		}
    $Output = New-Object psobject -Property $hash
	$OSInfo += $Output
    $hash = @{
		Label = "Processor $CPU_ID Logical Processor(s)"
		Value = $($PRocLPs)
		}
    $Output = New-Object psobject -Property $hash
	$OSInfo += $Output
	}
$hash = @{
    Label = "Total Processors Core(s) (Total)"
    Value = $($Procs | measure-object -Property NumberOfCores -sum).Sum
    }
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
$hash = @{
    Label = "Total Logical Processor(s) (Total)"
    Value = $($Procs | measure-object -Property NumberOfLogicalProcessors -sum).Sum
    }
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
$hash = @{
    Label = "Hyper-Threading"
    Value = If ( $($($Procs | measure-object -Property NumberOfLogicalProcessors -sum).Sum) -gt $($($Procs | measure-object -Property NumberOfCores -sum).Sum) )  { "Enabled" } Else { "Disabled" }
    }
$Output = New-Object psobject -Property $hash
$OSInfo += $Output

ForEach ($PageFile in $PageFiles) {
	$PFName = $PageFile.Name
	$PFInitSize = $PageFile.InitialSize
	$PFMaxSize = $PageFile.MaximumSize
	IF ($PFMaxSize -eq 0) {
		$hash = @{
			Label = "Pagefile Name $PFName"
			Value = "System Managed Size"
			}
		}
	Else {
		$hash = @{
			Label = "Pagefile Name $PFName"
			Value = "Initial Size $PFInitSize Maximum Size $PFMaxSize"
			}
		}
	$Output = New-Object psobject -Property $hash
	$OSInfo += $Output
	}

If ($AutoPageFile -eq $true) {
	$hash = @{
		Label = "Pagefile Setting"
		Value = "Automatically manage paging file sizes for all drives"
		}
}
Else {
	$hash = @{
		Label = "Pagefile Setting"
		Value = "Paging file sizes manually specified for each drive"
}
	$Output = New-Object psobject -Property $hash
	$OSInfo += $Output
	}

$hash = @{
	Label = "Time Zone"
	Value = $TimeZone
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output


ForEach ($Locale in $Locales) {
	$LocaleUser = $Locale.User
	$LocaleRegion = $Locale.LocaleName
	$hash = @{
		Label = "Locale"
		Value = "$LocaleUser ($LocaleRegion)"
		}
	$Output = New-Object psobject -Property $hash
	$OSInfo += $Output
	}

#Write-Output "Operating System : $OSVer"
#Write-Output "Service Pack : $SPVer"
#Write-Output "Serial Number : $Serial"
#Write-Output "Timezone : $TimeZone"
#End operating system & service

#Memory settings, obtained from WMI
$Ram = [Math]::Round((Get-WmiObject -Class Win32_ComputerSystem).totalphysicalmemory/1gb)
$hash = @{
	Label = "Physical Memory"
	Value = "$Ram GB"
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
#Write-Output "Physical Memory : $Ram GB"
#end memory settings

#Crash dump settings, obtain from registry
$RegRet = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl").CrashDumpEnabled
Switch ($RegRet) {
	0 {$CrashDump = "No Memory Dump"}
	1 {$CrashDump = "Complete Memory Dump"}
	2 {$CrashDump = "Kernel Memory Dump"}
	3 {$CrashDump = "Small Memory Dump"}
	7 {$CrashDump = "Automatic memory dump"}
	Default {$CrashDump = "Could Not Determine Memory Dump Setting"}
}
$hash = @{
	Label = "Startup & Recovery"
	Value = $CrashDump
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
#Write-Output "Memory Dump Setting : $CrashDump"
#end crash dump settings

#PowerPlan Setting
$hash = @{
	Label = "Power Plan Setting"
	Value = "$PowerPlan"
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
#end PowerPlan Setting

#WSUS Setting
IF (Test-Path "HKLM:\SOFTWARE\EMIS")
	{$WSUSStage = (Get-ItemProperty "HKLM:\SOFTWARE\EMIS").WSUSStage}
ELSE
	{$WSUSStage = "Not Set"}
$hash = @{
	Label = "WSUS Setting"
	Value = "WSUSStage $WSUSStage"
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
#Write-Output "WSUS Setting : WSUSStage $WSUSStage"
#end startup & recovery options

#Obtain License activation confirmation
$Lic = get-wmiobject -class SoftwareLicensingProduct
$License =  $Lic | Select | where {$_.LicenseStatus -eq 1} | ForEach {$_.Description}

If ($License) {
	$hash = @{
	Label = $License
	Value = "Activated"
		}
	}
Else {
	$hash = @{
	Label = "Windows License"
	Value = "Not Activated"
		}
	}
$Output = New-Object psobject -Property $hash
$OSInfo += $Output
#Write-Output "License : $License"

#End Obtain License activation confirmation

#Write-Host "User Rights"
#Extended User Rights
<#
If ($OSVer -match "2008") {
	$DNDomain = 'DC='+(gwmi win32_computersystem).domain.replace('.',',DC=')
	$root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$GPLiveDC/$DNDomain",$cred.getNetworkCredential().username,$cred.getNetworkCredential().password)
	$ComputerName = $env:COMPUTERNAME
	$searcher = New-Object System.DirectoryServices.DirectorySearcher($root)
	$searcher.Filter = "(&(objectClass=computer)(name=$ComputerName))"
	[System.DirectoryServices.SearchResult]$result = $searcher.FindOne()
	#$result.path -split('//')[1]
	#Write-Host "result path:" $result.path
	$DSaclsCmd = (($result.path) -split('/'))[3]
	#Write-Host "Obtaining User Rights:" $DSaclsCmd
	$pssession = New-PSSession -ComputerName "$GPLiveDc" -Credential $cred
	$UserRights = Invoke-Command -Session $pssession -Script { DSACLS $args[0] } -Args $DSaclsCmd
	$UserRights = $UserRights | where {$_ -like "*Allowed to Authenticate*"}
	$URs = @()
	If (!($UserRights -eq $null)) {
		Foreach ($UserRight in $UserRights) {
			$UserRight = $UserRight.substring(6,32)
			$URs += $UserRight.trim()
			$hash = @{
				Label = "Group Allowed to Authenticate"
				Value = $UserRight.trim()
				}
			$Output = New-Object psobject -Property $hash
			$OSInfo += $Output
			}
		}

	#Write-OutPut $URs
	Get-PSSession | Remove-PSSession
	#Write-Host "End User Rights"
	}
#end extended user rights
#>

#Write-Host "GPOs"
#GPO Settings
#GPO Settings use gpresult then search for Applied objects
$GPResult = gpresult /r
IF ($GPResult -match "does not have RSOP data.") {$GPResult = gpresult /r /user *}
##$GPResult = gpresult /scope User /r
##IF ($GPResult -match "does not have RSOP data.") {$GPResult = gpresult /r /scope User /user *}
#Write-Output $GPResult
#To deal with no RSOP
If ( !($GPResult -match "does not have RSOP data.") ) {
    $arrpos = [array]::indexof($GPResult,"    Applied Group Policy Objects")
    #If ($arrpos) {Write-Output "Gpresult success"}
    $GPOResults =@()
    If ($arrpos) {
	    for ($i = $arrpos+2; $i -le $GPResult.length; $i++) {
		    If ($GPResult[$i] -like "*The following GPOs were not applied because they were filtered out*" -or $GPResult[$i] -like "*The computer is a part of the following security groups*") {break}
		    $GPOResults += $GPResult[$i]
		    }
	    #Remove empty value from array
	    $GPOResult = @()
	    Foreach ($a in $GPOResults) {
		    IF (!($a -eq "")) {
			    $GPOResult += $a.trim()
			    $hash = @{
				    Label = "Applied GPO"
				    Value = $a.trim()
				    }
			    $Output = New-Object psobject -Property $hash
			    $OSInfo += $Output
			    }
		    }
	    }
    }
ELSE {
    Write-Host "GPOs cannot be enumerated"
    $hash = @{
		Label = "GPOs"
		Value = "Unable to enumerate: $GPResult"
		}
	$Output = New-Object psobject -Property $hash
	$OSInfo += $Output
    }

#Write-Output $GPOResult
#end gpo settings

#Write-Host "Local Admins"
#Local Access
$LocalAdmins = net localgroup administrators | where {$_ -AND $_ -notmatch "command completed successfully"} | select -skip 4
Foreach ($a in $LocalAdmins) {
	$hash = @{
			Label = "Local Administrator"
			Value = $a
		}
		$Output = New-Object psobject -Property $hash
		$OSInfo += $Output
	}
$LocalRDPUsers = net localgroup "Remote Desktop Users" | where {$_ -AND $_ -notmatch "command completed successfully"} | select -skip 4
Foreach ($a in $LocalRDPUsers) {
	$hash = @{
			Label = "Remote Desktop User"
			Value = $a
		}
		$Output = New-Object psobject -Property $hash
		$OSInfo += $Output
	}
#End LocalAccess

#Write-Host "Firewalls"
######to test # works only on PS3 (2012) and beyond ####
#gpresult /r | select-string "firewall" | % {Get-NetFirewallProfile -PolicyStore preprod.emishosting.com\"$_" | select name, enabled}
###need this one..... Get-NetFirewallProfile -PolicyStore ActiveStore

#Determine firewall settings using netsh command
If ($OSVer -match "2008") {
	$Firewalls = netsh advfirewall show currentprofile state
	$DomFireWarrpos = [array]::indexof($Firewalls,"Domain Profile Settings: ")
	$PubFireWarrpos = [array]::indexof($Firewalls,"Public Profile Settings: ")
	IF ($DomFireWarrpos -ne $null) {
		Switch ($Firewalls[$DomFireWarrpos+2]) {
			{$_ -like "*OFF*"} {$ProfSet = "OFF"}
			{$_ -like "*ON*"} {$ProfSet = "ON"}
			default {$ProfSet = "Unknown"}
		}
		$DomFireWall = $Firewalls[$DomFireWarrpos] +$ProfSet
		$DomFireWallSet = $ProfSet
	}
	IF ($PubFireWarrpos -ne $null) {
		Switch ($Firewalls[$PubFireWarrpos+2]) {
			{$_ -like "*OFF*"} {$ProfSet = "OFF"}
			{$_ -like "*ON*"} {$ProfSet = "ON"}
			default {$ProfSet = "Unknown"}
		}
		$PubFireWall = $Firewalls[$PubFireWarrpos] +$ProfSet
		$PubFireWallSet = $ProfSet
	}
	IF ($DomFireWallSet -ne $null) {
		$hash = @{
			Label = "Domain Firewall"
			Value = $DomFireWallSet
			}
		$Output = New-Object psobject -Property $hash
		$OSInfo += $Output
		}
	IF ($PubFireWallSet -ne $null) {
		$hash = @{
			Label = "Public Firewall"
			Value = $PubFireWallSet
			}
		$Output = New-Object psobject -Property $hash
		$OSInfo += $Output
		}
	}

#Determine firewall settings using powershell cmdlets
If ($OSVer -match "2012|2016|2019") {
	$Hash = @{Label="Domain Firewall";Value="Unknown"}
	Switch (((Get-NetFirewallProfile -PolicyStore ActiveStore) | ? {$_.name -eq "Domain"}).enabled) {
		$false {$Hash = @{Label="Domain Firewall";Value="OFF"}}
		$true {$Hash = @{Label="Domain Firewall";Value="ON"}}
		Default {$Hash = @{Label="Domain Firewall";Value="Unknown"}}
		}
	$Output = New-Object psobject -Property $hash
	$OSInfo += $Output

	$Hash = @{Label="Public Firewall";Value="Unknown"}
	Switch (((Get-NetFirewallProfile -PolicyStore ActiveStore) | ? {$_.name -eq "Public"}).enabled) {
		$false {$Hash = @{Label="Public Firewall";Value="OFF"}}
		$true {$Hash = @{Label="Public Firewall";Value="ON"}}
		Default {$Hash = @{Label="Public Firewall";Value="Unknown"}}
		}
	$Output = New-Object psobject -Property $hash
	$OSInfo += $Output
	}

#IF ($DomFireWall -ne $null) {Write-Output "Domain Firewall : $DomFireWall"}
#IF ($PubFireWall -ne $null) {Write-Output "Public Firewall : $PubFireWall"}
#end firewall settings

#NIC Config New Version 25/02/2022
#Change prompted by intresting situation when VM has a disconnected NIC
#Shorter improved dynamic version now

function Get-IPv4SubnetMask {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [int[]]
        [ValidateRange(1,32)]
        $NetworkLength
    )
    process {
        foreach ($Length in $NetworkLength) {
            $MaskBinary = ('1' * $Length).PadRight(32, '0')
            $DottedMaskBinary = $MaskBinary -replace '(.{8}(?!\z))', '${1}.'
            $SubnetMask = ($DottedMaskBinary.Split('.') | foreach { [Convert]::ToInt32($_, 2) }) -join '.'
            $SubnetMask
        }
    }
}

If ( $OSVer -match "2012|2016|2019" ) {

    #MH 10/01/2023 - modified to cope with DHCP assigned addresses on Staging
    #$NICs = Get-NetIPAddress | ? PrefixOrigin -eq "Manual"
    $NICs = Get-NetIPAddress | ? PrefixOrigin -match "Manual|DHCP"

    $NICInfo = @()
    ForEach ( $NIC in $NICs ) {
        $IPConfig = Get-NetIPConfiguration -InterfaceIndex $Nic.InterfaceIndex
        $hash = @{
		    Label = $($NIC.InterfaceAlias)
		    Value = $($NIC.IPAddress)
            DG = $( If ( $($IPConfig.IPv4DefaultGateway.NextHop) ) { $($IPConfig.IPv4DefaultGateway.NextHop) } Else { "None Configured" } )
            Mask = $(Get-IPv4SubnetMask $($Nic.PrefixLength))
            Status = $($IPConfig.NetAdapter.Status)
		    }
	    $Output = New-Object psobject -Property $hash
	    $NetworkInfo += $Output
        }
    }

#End New Network Config gathering


#Discover NIC IPs DB Servers 2008
#If ($Service -eq "DB Servers" -and $OSVer -match "2008") {
If ( ( get-service | ? {$_.displayname -match "SQL Server"}) -and $OSVer -match "2008") {
    #Write-Host "NICs DB 2008"
	$PrivateNICName = "Unknown"
	$CampusNICName = "Unknown"
	$HB2BackupNICName = "Unknown"
	New-PSDrive -Name HPProg -PSProvider FileSystem -Root "C:\Program Files\HP\NCU" #Have to map drive locally when PSRemoting
	IF ((get-psdrive | where {$_.name -match "HPProg"})) {
		$HPNics = HPProg:\hpnetsvy.exe /f"C:\Program Files\HP\NCU\HPNICtemp.txt" #Run HP Util to collect NIC Information
		$LineNumbers = get-content HPProg:\HPNICTemp.txt | select-string -Pattern "  Team Name                                   =" #Search file for string, use linenumbers in array
		$LineNums = $LineNumbers | % {$_.linenumber}
#		$LineNums
		ForEach ($LineNum in $LineNums) {
			$LineNum = [convert]::toint32($LineNum)
			$TempTeam = (get-content "HPProg:\HPNICTemp.txt")[$LineNum -1]
			$TempName = (get-content "HPProg:\HPNICTemp.txt")[$LineNum]
			$TempName = $tempname.split("=")
			If ($TempTeam -like "*Private Team*") {$PrivateNICName = $TempName[1].trim()}
			ElseIf ($TempTeam -like "*Campus Team*") {$CampusNICName = $TempName[1].trim()}
			}
		Remove-PSDrive HPProg
		}
	$PrivateNIC = Get-WmiObject -Class Win32_NetworkAdapter NetConnectionID | Select-Object | Where {$_.NetConnectionID -like "*private team*"} | %{$_.NetConnectionID}
	$CampusNIC = Get-WmiObject -Class Win32_NetworkAdapter NetConnectionID | Select-Object | Where {$_.NetConnectionID -like "*campus team*"} | %{$_.NetConnectionID}
	$HB2BackupNIC = Get-WmiObject -Class Win32_NetworkAdapter NetConnectionID | Select-Object | Where {$_.NetConnectionID -like "*hb2 backup*"} | %{$_.NetConnectionID}
	#$HB2BackupNICName = Get-WmiObject -Class Win32_NetworkAdapter | Select-Object | Where {$_.NetConnectionID -like "*HB2 Backup*"} | % {$_.name}
	IF (!$PrivateNIC) {"Private Team not discovered"}
	IF (!$CampusNIC) {"Campus Team not discovered"}
	IF (!$HB2BackupNIC) {"HB2 Backup NIC not discovered"}
	$PrivateIP = @()
	IF ($PrivateNIC) {
		$PrivateIPs = netsh interface ipv4 show config "$PrivateNIC" | find /i "ip address"
		$PrivateDG = (netsh interface ipv4 show config "$PrivateNIC" | find /i "Default Gateway")
        If ($PrivateDG -is [System.Array]) {
            IF ($PrivateDG) {$PrivateDG = ($PrivateDG[0]).Split(':)')[1].trim()} else {$PrivateDG = "None Configured"}
            }
        Else {
            IF ($PrivateDG) {$PrivateDG = ($PrivateDG).Split(':)')[1].trim()} else {$PrivateDG = "None Configured"}
            }
		$PrivateSN = netsh interface ipv4 show config "$PrivateNIC" | find /i "Subnet Prefix"
        If ($PrivateSN -is [System.Array]) {
            IF ($PrivateSN) {$PrivateSN = ($PrivateSN[0]).Split('mask|)')[4].trim()} else {$PrivateSN = "None Configured"}
            }
        Else {
            IF ($PrivateSN) {$PrivateSN = ($PrivateSN).Split('mask|)')[4].trim()} else {$PrivateSN = "None Configured"}
            }
		If ($PrivateIPs -is [System.Array]) {
			ForEach ($a in $PrivateIPs) {
				$IP = $a.split(":")
				$PrivateIP += $ip[1].trim()
				$hash = @{
					#Label = "Private Team - $PrivateNICName"
					Label = "$PrivateNIC"
					Value = $ip[1].trim()
                    DG = $PrivateDG
                    Mask = $PrivateSN
					}
				$Output = New-Object psobject -Property $hash
				$NetworkInfo += $Output
				}
			}
		Else {
			$IP = $PrivateIPs.split(":")
			$PrivateIP += $ip[1].trim()
			$hash = @{
				#Label = "Private Team - $PrivateNICName"
				Label = "$PrivateNIC"
				Value = $ip[1].trim()
                DG = $PrivateDG
                Mask = $PrivateSN
				}
			$Output = New-Object psobject -Property $hash
			$NetworkInfo += $Output
			}
			#Write-Output "Private Ips - $PrivateNICName" $PrivateIP
		}
	$CampusIP = @()
	IF ($CampusNIC) {
		$CampusIPs = netsh interface ipv4 show config "$CampusNIC" | find /i "ip address"
		$CampusDG = netsh interface ipv4 show config "$CampusNIC" | find /i "Default Gateway"
        If ($CampusDG -is [System.Array]) {
            IF ($CampusDG) {$CampusDG = ($CampusDG[0]).Split(':)')[1].trim()} else {$CampusDG = "None Configured"}
            }
        Else {
		    IF ($CampusDG) {$CampusDG = ($CampusDG).Split(':)')[1].trim()} else {$CampusDG = "None Configured"}
            }
		$CampusSN = netsh interface ipv4 show config "$CampusNIC" | find /i "Subnet Prefix"
        If ($CampusSN -is [System.Array]) {
            IF ($CampusSN) {$CampusSN = ($CampusSN[0]).Split('mask|)')[4].trim()} else {$CampusSN = "None Configured"}
            }
        Else {
            IF ($CampusSN) {$CampusSN = ($CampusSN).Split('mask|)')[4].trim()} else {$CampusSN = "None Configured"}
            }
        If ($CampusIPs -is [System.Array]) {
			ForEach ($a in $CampusIPs) {
				$IP = $a.split(":")
				$CampusIP += $ip[1].trim()
				$hash = @{
					#Label = "Campus Team - $CampusNICName"
					Label = "$CampusNIC"
					Value = $ip[1].trim()
                    DG = $CampusDG
                    Mask = $CampusSN
					}
				$Output = New-Object psobject -Property $hash
				$NetworkInfo += $Output
				}
			}
		ELSE {
			$IP = $CampusIPs.split(":")
			$CampusIP += $ip[1].trim()
			$hash = @{
				#Label = "Campus Team - $CampusNICName"
				Label = "$CampusNIC"
				Value = $ip[1].trim()
                DG = $CampusDG
                Mask = $CampusSN
				}
			$Output = New-Object psobject -Property $hash
			$NetworkInfo += $Output
			}
			#Write-Output "Campus Ips - $CampusNICName" $CampusIP
		}
	$HB2BackupIP = @()
	IF ($HB2BackupNIC) {
		$HB2BackupIPs = netsh interface ipv4 show config "$HB2BackupNIC" | find /i "ip address"

        $HB2BackupDG = netsh interface ipv4 show config "$HB2BackupNIC" | find /i "Default Gateway"
        If ($HB2BackupDG -is [System.Array]) {
            IF ($HB2BackupDG) {$HB2BackupDG = ($HB2BackupDG[0]).Split(':)')[1].trim()} else {$HB2BackupDG = "None Configured"}
            }
        Else {
            IF ($HB2BackupDG) {$HB2BackupDG = ($HB2BackupDG).Split(':)')[1].trim()} else {$HB2BackupDG = "None Configured"}
            }

        $HB2BackupSN = netsh interface ipv4 show config "$HB2BackupNIC" | find /i "Subnet Prefix"
        If ($HB2BackupSN -is [System.Array]) {
            IF ($HB2BackupSN) {$HB2BackupSN = ($HB2BackupSN[0]).Split('mask|)')[4].trim()} else {$HB2BackupSN = "None Configured"}
            }
        ELSE {
            IF ($HB2BackupSN) {$HB2BackupSN = ($HB2BackupSN).Split('mask|)')[4].trim()} else {$HB2BackupSN = "None Configured"}
            }

		If ($HB2BackupIPs -is [System.Array]) {
			ForEach ($a in $HB2BackupIPs) {
				$IP = $a.split(":")
				$HB2BackupIP += $ip[1].trim()
				$hash = @{
					#Label = "HB2 Backup - $HB2BackupNICName"
					Label = "$HB2BackupNIC"
					Value = $ip[1].trim()
                    DG = $HB2BackupDG
                    Mask = $HB2BackupSN
					}
				$Output = New-Object psobject -Property $hash
				$NetworkInfo += $Output
				}
			}
		ELSE {
			$IP = $HB2BackupIPs.split(":")
			$HB2BackupIP += $ip[1].trim()
			$hash = @{
				#Label = "HB2 Backup - $HB2BackupNICName"
				Label = "$HB2BackupNIC"
				Value = $ip[1].trim()
                DG = $HB2BackupDG
                Mask = $HB2BackupSN
				}
			$Output = New-Object psobject -Property $hash
			$NetworkInfo += $Output
			}
			#Write-Output "HB2 Backup Ips - $HB2BackupNICName" $HB2BackupIP
		}
	}
#End discover cluster NIC IPs

#Obtain Cluster Information
#Edit 19/02/2015
#If ($Service -eq "DB Servers" -and $OSVer -match "2012") {
If ( $OSVer -match "2012" -and ( ( get-service | ? {$_.displayname -match "Cluster Service"}).status -eq "Running" ) ) {
#End 19/02/2015
    #Write-Host "Obtaining Cluster Information DB 2012"
	$ClusterName = (get-cluster).name
		$hash = @{
		Label = "Cluster Name"
		Value = $ClusterName
		}
	$Output = New-Object psobject -Property $hash
	$ClusterInfo += $Output
	$ClusterGroups = Get-ClusterGroup
	ForEach ($ClusterGroup in $ClusterGroups) {
		$CluGroup = $ClusterGroup.Name
		$CluOwner = $ClusterGroup.OwnerNode
		$CluState = $ClusterGroup.State
		$hash = @{
			Label = "Cluster Group: $CluGroup"
			Value = "Owner: $CluOwner / State: $CluState"
			}
		$Output = New-Object psobject -Property $hash
		$ClusterInfo += $Output
		}
	#Edit 26/09/2014
	#$QuorumResource	= (Get-ClusterQuorum).QuorumResource
	$QuorumType	= (Get-ClusterQuorum).QuorumType
	#End 26/09/2014
	If ($QuorumType) {
		#$QuorumDetails = Get-ClusterResource "$QuorumResource"
		#$QuorumType = $QuorumDetails.resourcetype.name

		$hash = @{
			Label = "Quorum Type: $ClusterName"
			value = $QuorumType
			}
		$Output = New-Object psobject -Property $hash
		$ClusterInfo += $Output

		IF ($QuorumType -eq "NodeAndFileShareMajority") {
			$QuorumDetails	= (Get-ClusterQuorum).QuorumResource
			#$QuorumDetails = Get-ClusterResource "$QuorumResource"

			$hash = @{
				Label = "Quorum State: $ClusterName"
				Value = $QuorumDetails.state
				}
			$Output = New-Object psobject -Property $hash
			$ClusterInfo += $Output
			#If ($QuorumType -eq "File Share Witness") {
			$CluSharePath = (Get-ClusterResource $QuorumDetails.name | Get-ClusterParameter | ? {$_.name -eq "SharePath"}).value
			$hash = @{
				Label = "Quorum Share Path: $ClusterName"
				Value = $CluSharePath
				}
			$Output = New-Object psobject -Property $hash
			$ClusterInfo += $Output
				#}
			}
		}
	Else {
		$hash = @{
			Label = "Cluster Quorum: $CluGroup"
			Value = "Not Found"
			}
		$Output = New-Object psobject -Property $hash
		$ClusterInfo += $Output
		}
	}


If ( $OSVer -match "2016|2019" -and ( ( get-service | ? {$_.displayname -match "Cluster Service"}).status -eq "Running" ) ) {
    #Write-Host "Obtaining Cluster Information DB 2019"
	$ClusterName = (get-cluster).name
		$hash = @{
		Label = "Cluster Name"
		Value = $ClusterName
		}
	$Output = New-Object psobject -Property $hash
	$ClusterInfo += $Output
	$ClusterGroups = Get-ClusterGroup
	ForEach ($ClusterGroup in $ClusterGroups) {
		$CluGroup = $ClusterGroup.Name
		$CluOwner = $ClusterGroup.OwnerNode
		$CluState = $ClusterGroup.State
		$hash = @{
			Label = "Cluster Group: $CluGroup"
			Value = "Owner: $CluOwner / State: $CluState"
			}
		$Output = New-Object psobject -Property $hash
		$ClusterInfo += $Output
		}

    $ClusterQuorum = Get-ClusterQuorum
    switch ($ClusterQuorum.QuorumType) { 'Majority' {
            if ($ClusterQuorum.QuorumResource -eq $null) {
                $ClusterQuorumType = 'NodeMajority'
                }
            elseif ($ClusterQuorum.QuorumResource.ResourceType.DisplayName -eq 'Physical Disk') {
                $ClusterQuorumType = 'NodeAndDiskMajority'
                }
            elseif ($ClusterQuorum.QuorumResource.ResourceType.DisplayName -eq 'File Share Quorum Witness') {
                $ClusterQuorumType = 'NodeAndFileShareMajority'
                }
            }
        }
    $hash = @{
		Label = "Quorum Type: $ClusterName"
		value = $ClusterQuorumType
		}
	$Output = New-Object psobject -Property $hash
	$ClusterInfo += $Output

    $hash = @{
		Label = "Quorum State: $ClusterName"
		Value = $ClusterQuorum.QuorumResource.state
		}
	$Output = New-Object psobject -Property $hash
	$ClusterInfo += $Output
    If ($ClusterQuorumType -eq "NodeAndFileShareMajority") {
        $CluSharePath = (Get-ClusterResource $ClusterQuorum.QuorumResource.name | Get-ClusterParameter | ? {$_.name -eq "SharePath"}).value
		$hash = @{
			Label = "Quorum Share Path: $ClusterName"
			Value = $CluSharePath
			}
		$Output = New-Object psobject -Property $hash
		$ClusterInfo += $Output
        }
    #Cluster Heartbeats
    $ClusterBits = get-cluster
    $hash =@{Label = "CrossSubnetDelay"; Value = $ClusterBits.CrossSubnetDelay}
    $Output = New-Object psobject -Property $hash; $ClusterInfo += $Output
    $hash =@{Label = "CrossSubnetThreshold"; Value = $ClusterBits.CrossSubnetThreshold}
    $Output = New-Object psobject -Property $hash; $ClusterInfo += $Output
    $hash =@{Label = "SameSubnetDelay"; Value = $ClusterBits.SameSubnetDelay}
    $Output = New-Object psobject -Property $hash; $ClusterInfo += $Output
    $hash =@{Label = "SameSubnetThreshold"; Value = $ClusterBits.SameSubnetThreshold}
    $Output = New-Object psobject -Property $hash; $ClusterInfo += $Output
    $ClusSchedTasks = @()
    $ClusSchedTasks += Get-ClusteredScheduledTask
    ForEach ( $ClusSchedTask in $ClusSchedTasks ){
        $hash =@{Label = "Scheduled Task"; Value = "Name: $($ClusSchedTask.TaskName) / Type: $($ClusSchedTask.TaskType)"}
        $Output = New-Object psobject -Property $hash; $ClusterInfo += $Output
        }
    }
#End Cluster Information

#Write-Host "DNS Servers"
#DNS Servers
#Search cards that have DNS Server set
$DnsInfo=@()
$DNSTemp = get-wmiobject Win32_NetworkAdapterConfiguration -filter "IPEnabled='True'" | select Description,DNSServerSearchOrder | where {$_.DNSServerSearchOrder -ne $null}
foreach ($a in $DNSTemp) {
	$b = $a.DNSServerSearchOrder
	$Count = 1
	foreach ($y in $b) {
        If ($OSVer -match "2012|2016|2019") {
            $NICLabel = (Get-NetAdapter -InterfaceDescription $($a.Description)).Name
            }
        Else {
		    $NICLabel = (Get-WmiObject -Class Win32_NetworkAdapter | Where {$_.Name -eq ($a.description)}).netconnectionid
            }
		Switch ($Count) {
			1 {$DNSSearchNum = "Primary"}
			2 {$DNSSearchNum = "Secondary"}
			3 {$DNSSearchNum = "Tertiary"}
			4 {$DNSSearchNum = "Quaternary"}
			5 {$DNSSearchNum = "Quinary"}
			default {$DNSSearchNum = "Other"}
			}
		$hash = @{
			Label = $NICLabel
			Order = $DNSSearchNum
			Value = $y
			}
		$Output = New-Object psobject -Property $hash
		$DNSInfo += $Output
		$Count++
		}
	}
#End DNS Servers

#Routes
#Write-Host "Route Configuration"
$Routes = gwmi win32_IP4RouteTable | ? {$_.type -eq 4 -and $_.destination -ne "0.0.0.0"} | select Destination, Mask, NextHop, InterfaceIndex
#$Routes
ForEach ($Route in $Routes) {
    #Write-Host "Route Index : $($Route.InterfaceIndex)"
    #netsh interface ipv4 show interfaces | select-string " $($Route.InterfaceIndex) "
    $RouteInfo += New-Object -TypeName PSObject -Property @{
        Destination = $Route.Destination
        Mask = $Route.Mask
        NextHop = $Route.NextHop
        InterFaceIndex = $Route.InterfaceIndex
        InterFaceName = ((netsh interface ipv4 show interfaces) | % {If ($_ -ne "") {IF ( $_.Substring(0,3).trim() -eq $($Route.InterfaceIndex) ) {$_} } }).substring(43)
        }
    #(netsh interface ipv4 show interfaces) | % {If ($_ -ne "") {Write-Host $_.Substring(0,3);IF ( $_.Substring(0,3).trim() -match $($Route.InterfaceIndex) ) {$_} Else {"Nothing"} } }
    }

#$RouteInfo | ft -AutoSize

#End Routes

#DataDog Services
If (( get-service | ? {$_.displayname -match "DataDog"})) {
	Write-Host "DataDog"
	$DataDogArr = @()
	$DDServices = gwmi win32_service -Filter "Name like 'Datadog%'"
	foreach ($DDService in $DDServices) {
		#IF (Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'" -ErrorAction Continue) {
			#$a = Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'"
			$AService = $DDService.name
			$State = $DDService.state
			$Mode = $DDService.startmode
			$RunAs = $DDService.StartName
			$DataDogArr += "$AService / $State / $Mode / $RunAs"
			$hash = @{
				Service = $DDService.name
				State = $DDService.state
				Mode = $DDService.startmode
				RunAs = $DDService.StartName
				}
			$Output = New-Object psobject -Property $hash
			$DataDogServices += $Output
			#}
		}
		Write-Output $DataDogArr
	}
#END DataDog Services

#Check DataDog Agent Version
If (Test-Path "C:\Program Files\Datadog\Datadog Agent") {
	Write-Host "DataDog Found"
	$DDVer = (Get-ItemProperty "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe").VersionInfo.productversion
	}
Else {
    Write-Host "DataDog Not Found!!"
	$DDVer = "Unknown"
    }

$hash = @{
	Label = "DataDog Agent Version"
	Value = $DDVer
	}
$Output = New-Object psobject -Property $hash
$ProgramInfo += $Output
Write-Output $DDVer
#End DataDog Agent Version



#Crowdstrike Check
If (Test-Path "C:\Program Files\CrowdStrike") {
	Write-Host "CroudStrike Found"
	$SAVVer = (Get-ItemProperty "C:\Program Files\CrowdStrike\CSFalconService.exe").VersionInfo.productversion
	$SAVService = (Get-service -Name *falcon*).DisplayName
	$SAVServiceStatus = (Get-service -Name *falcon*).Status
	$CSGroupTag = (Get-ItemProperty -Path "HKLM:\SYSTEM\CrowdStrike\{9b03c1d9-3138-44ed-9fae-d9f4c034b88d}\{16e0423f-7058-48c9-a204-725362b67639}\Default" -Name "GroupingTags").GroupingTags
}
Else {
    Write-Host "No AV Product Found!!"
	$SAVService = "Unknown"
	$SAVServiceStatus = "Unknown"
	$SAVVer = "Unknown"
	$CSGroupTag = "Unknown"
    }

$hash = @{
	Label = "AntiVirus Service Name"
	Value = "$SAVService"
	}
$Output = New-Object psobject -Property $hash
$AntiVirus += $Output
$hash = @{
	Label = "AntiVirus Service Status"
	Value = "$SAVServiceStatus"
	}
$Output = New-Object psobject -Property $hash
$AntiVirus += $Output
$hash = @{
	Label = "AntiVirus Program Version"
	Value = $SAVVer
	}
$Output = New-Object psobject -Property $hash
$AntiVirus += $Output
$hash = @{
	Label = "CrowdStrike Grouping Tag"
	Value = $CSGroupTag
	}
$Output = New-Object psobject -Property $hash
$AntiVirus += $Output
#End Crowdstrike check


#Nessus Version Check
#If (($Service -eq "DB Servers") -or ($Service -eq "App Servers")) {
If ( ( get-service | ? {$_.displayname -match "SQL Server"} ) -or ( get-service | ? {$_.displayname -match "Emis|SDS"}) -and $OSVer -match "2008|2012|2016|2019" ) {
	$NessusTemp = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* `
		|Select DisplayName, DisplayVersion, Publisher, InstallDate, HelpLink, UninstallString `
		| where {$_.displayname -like "*Nessus Agent*"}
	If ($NessusTemp) {
		$NessusProg = $NessusTemp.displayname
		$NessusProg += " : "
		$NessusProg += $NessusTemp.displayversion
		$hash = @{
			Label = "Nessus Agent Product"
			Value = $NessusTemp.displayname
			}
		$Output = New-Object psobject -Property $hash
		$ProgramInfo += $Output
		$hash = @{
			Label = "Nessus Agent Version"
			Value = $NessusTemp.displayversion
			}
		$Output = New-Object psobject -Property $hash
		$ProgramInfo += $Output
		}
	#Write-Output $SCProg
	}
#End Nessus Version Check
#<#
#Telegraf Services
#If ($Service -eq "DB Servers") {
#gwmi win32_service | ? name -eq "ucp-telegraf" | select *
# If (( get-service | ? {$_.name -match "ucp-telegraf"})) {
#     #Write-Host "vrops"
# 	$TelegrafArr = @()
# 	$TelegrafServicesvRops = gwmi win32_service -Filter "Name like 'ucp-%'"
# 	foreach ($TelegrafService in $TelegrafServicesvRops) {
# 		#IF (Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'" -ErrorAction Continue) {
# 			#$a = Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'"
# 			$AService = $TelegrafService.name
# 			$State = $TelegrafService.state
# 			$Mode = $TelegrafService.startmode
# 			$RunAs = $TelegrafService.StartName
# 			$TelegrafArr += "$AService / $State / $Mode / $RunAs"
# 			$hash = @{
# 				Service = $TelegrafService.name
# 				State = $TelegrafService.state
# 				Mode = $TelegrafService.startmode
# 				RunAs = $TelegrafService.StartName
# 				}
# 			$Output = New-Object psobject -Property $hash
# 			$MonitoringServices += $Output
# 			#}
# 		}
# 		Write-Output $TelegrafArr
# 	}
#END Telegraf Services
#>

#Log Insight Services
#If ($Service -eq "DB Servers") {
#gwmi win32_service | ? name -eq "ucp-telegraf" | select *
# If (( get-service | ? {$_.name -match "LogInsight"})) {
#     #Write-Host "Log Insight"
# 	$LogInsightArr = @()
# 	$LogInsightServicesvRops = gwmi win32_service -Filter "Name like 'LogInsight%'"
# 	foreach ($LogInsightService in $LogInsightServicesvRops) {
#         #Write-Host "Log Insight"
# 		#IF (Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'" -ErrorAction Continue) {
# 		#$a = Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'"
# 		$AService = $LogInsightService.name
# 		$State = $LogInsightService.state
# 		$Mode = $LogInsightService.startmode
# 		$RunAs = $LogInsightService.StartName
# 		$LogInsightArr += "$AService / $State / $Mode / $RunAs"
# 		$hash = @{
# 			Service = $LogInsightService.name
# 			State = $LogInsightService.state
# 			Mode = $LogInsightService.startmode
# 			RunAs = $LogInsightService.StartName
# 			}
# 		$Output = New-Object psobject -Property $hash
# 		$MonitoringServices += $Output
# 		#}
# 	    }
# 		Write-Output $LogInsightArr
# 	}
#END Log Insight Services
#>

<#
#vRorps Version Check Can't perform no version on service files
#If (($Service -eq "DB Servers") -or ($Service -eq "App Servers")) {
If ( ( get-service | ? {$_.displayname -match "SQL Server"} ) -or ( get-service | ? {$_.displayname -match "Emis"}) -and $OSVer -match "2019" ) {
    #Write-Host "System Centre"
	$vRopTemp = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* `
		|Select DisplayName, DisplayVersion, Publisher, InstallDate, HelpLink, UninstallString `
		| where {$_.displayname -like "*System Center 2012 - Operations Manager Agent*" -OR $_.displayname -match "Microsoft Monitoring Agent"}
	If ($SCTemp) {
		$SCProg = $SCTemp.displayname
		$SCProg += " : "
		$SCProg += $SCTemp.displayversion
		$hash = @{
			Label = "System Center Op Man Agent Product"
			Value = $SCTemp.displayname
			}
		$Output = New-Object psobject -Property $hash
		$ProgramInfo += $Output
		$hash = @{
			Label = "System Center Op Man Agent Version"
			Value = $SCTemp.displayversion
			}
		$Output = New-Object psobject -Property $hash
		$ProgramInfo += $Output
		}
	ELSE {
		$hash = @{
			Label = "System Center Op Man Agent"
			Value = "Not Installed"
			}
		$Output = New-Object psobject -Property $hash
		$ProgramInfo += $Output
		}

	#Write-Output $SCProg
	}
#End Systems Center Version Check
#>

#SQL Audit
#If ($Service -eq "DB Servers") {
If ( ( get-service | ? {$_.displayname -match "SQL Server"} ) ) {
    #Write-Host "SQL Audit"
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null
	$MSQL = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer')#Place server name here in single quotes when connecting to another machine
	$MSQLInstance = $MSQL.serverinstances | % {$_.name}
	$MSQLInstances = @()
	ForEach ($Instance in $MSQLInstance) {
		$a = $MSQL.services | Where {$_.ServiceState -eq "Running" -and $_.displayname -eq "SQL Server ($instance)"}
		IF ($a)
			{$MSQLInstances += $Instance}
		Else
			{$MSQLInstancesReg += $Instance}
		}
	foreach ($Instance in $MSQLInstances) {
		$s = New-Object "Microsoft.SqlServer.Management.Smo.Server" .\$Instance
		$SQLPath = $s.RootDirectory.toupper()
		$SQLEdition = $s.Edition
		$SQLVersion = $s.ResourceVersionString.tostring()
		$SRVCollation = $s.Collation
		$Version = $SQLHash.Get_Item($SQLVersion)
		IF (!($Version)) {$Version = "Unknown"}
		$DBs = $s.databases
		$DBCollation = @()
		foreach ($DB in $DBs) {
			$DBCollation += ("Database : " +$DB.name +" - " +$DB.collation)
			}
		$MaxMem = [Math]::Round(($s.configuration.MaxServerMemory.RunValue)/1KB)
		$Para = $s.configuration.MaxDegreeOfParallelism.RunValue
		$Threads = $s.configuration.maxworkerthreads.RunValue
		$SLogins = $s.logins
		$RoleUser = @()
		$temp = foreach($SUser in $SLogins) {
			foreach ($role in $SUser.listmembers()) {
				$RoleUser += ($role +"`t" +$SUser.name)
				$hash = @{
					Instance = $Instance
					Label = $Role
					Value = $SUser.name
					}
				$Output = New-Object psobject -Property $hash
				$SQLServerAccess += $Output
				}
			}
        #fudge to collect an emishoting account
		#$TempLogins = $s.logins | where {$_.name -like "$domain*" -OR $_.name -like "EmisHosting*" -And $_.Name -notlike "Emishosting\Domain Admins"} | select name #Commented out 08-06-2023
		$TempLogins = $s.logins | where {$_.name -like "$DomainName*" -OR $_.name -like "EmisHosting*" -And $_.Name -notlike "Emishosting\Domain Admins"} | select name #Added 08-06-2023
		#Write-Host "Temp Logins" $TempLogins

<# Section seems
		IF ($OSVer -match "2012|2016|2019") {
			#$Domain=(([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).name.split(".")[0]).replace($Domain, "EMISPRDENG")
			#$Domain = $DomainShort.replace($DomainShort, "EMISPRDENG")
			$Domain = $DomainShort.replace($DomainShort, "EMISPRDENG")
			$DomainRoot =  ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().name).replace(".",", dc=")
			}

		IF ($OSVer -match "2008") {
			$Domain = (get-wmiobject WIN32_ComputerSystem).Domain.split(".")[0]
			$Domainroot = 'DC='+(gwmi win32_computersystem).domain.replace('.',',DC=')
			}
#>


		#Write-Host "Temp Logins Domain:" $Domain
		#Write-Host "Temp Logins Domainroot:" $DomainRoot
		#Write-Host "DC :" $GPLiveDC

		#Write-Host $Domain
		#Write-Host $DomainRoot
		ForEach ($TempLogin in $TempLogins) {
            #07/02/21 added to cope with user from other domains
            $strDomain = $TempLogin.name.split("\")[0]
			$user = $TempLogin.name.split("\")[1]
		    $FullUser = $TempLogin.name
			#Write-Output $FullUser
		    #Write-Host "SQL login" $user
		    #Write-Host "SQL login" $FullUser
		    #$objSearcher.SearchRoot = "LDAP://dc=$Domainroot"
			IF ($OSVer -match "2012|2016|2019") {

                #07/02/21 added to cope with user from other domains
                $domainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $strDomain)
                $domainroot = ([System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($domainContext).Name).replace(".",", dc=")
                #$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($domainContext)

                $ad = New-Object System.DirectoryServices.DirectoryEntry("LDAP://DC=$Domainroot",$cred.username,$cred.getNetworkCredential().password)
				#$ad = New-Object System.DirectoryServices.DirectoryEntry("LDAP://DC=$Domainroot")
				$objSearcher = New-Object System.DirectoryServices.DirectorySearcher($ad)
				$objSearcher.SearchRoot = $ad
				$objSearcher.Filter = ("(SamAccountName=$user)")
				$result = $objsearcher.findall()
				}

            <#
            IF ($OSVer -match "2008") {
				$ad = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$GPLiveDC/$Domainroot",$cred.getNetworkCredential().username,$cred.getNetworkCredential().password)
				$objSearcher = New-Object System.DirectoryServices.DirectorySearcher($ad)
				$objSearcher.SearchRoot = $ad
				$objSearcher.Filter = "((SamAccountName=$user))"
				[System.DirectoryServices.SearchResult]$result = $objsearcher.findone()
				} #>
			#if ($result.properties.objectclass -match "group") {$ObjType = "Group"}
	   		#if ($result.properties.objectclass -match "person") {$ObjType = "User"}
			#$ObjType = "Unknown"
			if (($result | Select -ExpandProperty Properties).objectclass -match "group") {$ObjType = "Group"}
	   		if (($result | Select -ExpandProperty Properties).objectclass -match "person") {$ObjType = "User"}
			#Write-Host "Object Type: $($ObjType) -- Name: ($FullUser)"

			#Write-Host "Group:" $ObjType
			$hash = @{
					Instance = $Instance
					Label = $ObjType
					Value = $FullUser
				}
				$Output = New-Object psobject -Property $hash
				#Write-Host $Output
				$SQLLogins += $Output
			}
		#Write-Output "SQL Instance : $Instance"
		#Write-Output "========================="
		#Write-Output "SQL Path : $SQLPath"`
		#"SQL Edition : $SQLEdition"`
		#"SQL Version : $SQLVersion / $Version "`
		#"SQL Server Collation : $SRVCollation"`
		#"DataBase Collations :-"`
		#$DBCollation
		#Write-Output "SQL Max Memory Setting : $MaxMem GB"`
		#"SQL Max Degree of Parallelism : $Para"`
		#"Role`t`tUser"`
		#"===================="
		#$RoleUser
		$hash = @{
			Instance = $Instance
			Label = "SQL Path"
			Value = $SQLPath
			}
		$Output = New-Object psobject -Property $hash
		$SQLInfo += $Output
		$hash = @{
			Instance = $Instance
			Label = "SQL Edition"
			Value = $SQLEdition
			}
		$Output = New-Object psobject -Property $hash
		$SQLInfo += $Output
		$hash = @{
			Instance = $Instance
			Label = "SQL Version"
			Value = "$SQLVersion / $Version"
			}
		$Output = New-Object psobject -Property $hash
		$SQLInfo += $Output
		$hash = @{
			Instance = $Instance
			Label = "SQL Max Memory Setting"
			Value = "$MaxMem GB"
			}
		$Output = New-Object psobject -Property $hash
		$SQLInfo += $Output
		$hash = @{
			Instance = $Instance
			Label = "SQL Max Degree of Parallelism"
			Value = $Para
			}
		$Output = New-Object psobject -Property $hash
		$SQLInfo += $Output
		$hash = @{
			Instance = $Instance
			Label = "SQL Max Worker Threads"
			Value = $Threads
			}
		$Output = New-Object psobject -Property $hash
		$SQLInfo += $Output
		$hash = @{
			Instance = $Instance
			Label = "SQL Server Collation"
			Value = $SRVCollation
			}
		$Output = New-Object psobject -Property $hash
		$SQLInfo += $Output
		}
	foreach ($Instance in $MSQLInstancesReg) {
		$inst = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
		foreach ($i in $inst) {
			If ($Instance -match $i) {
				$p = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$i
				$SQLEdition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Edition
				$SRVCollation = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").Collation
				$SQLVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").PatchLevel
				$SQLPath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\Setup").SQLDataRoot
				#Registry version doesn't always return correct version number
				#Returned value needs to be stripped so wildcards can be added to check hash (Xml)
				$TempVer = $SQLVersion.split(".")
				$VerCheck = $TempVer[0] +"*" +$TempVer[2] +"*"
				$Version = $SQLHash | foreach {$_.getenumerator()} | foreach {if($_.key -like $VerCheck) {$_.value}}
				IF (!($Version)) {$Version = "Unknown"}
				#Write-Output "SQL Instance : $i (From Registry)"
				#Write-Output "========================="
				#Write-Output "SQL Path : $SQLPath"`
				#"SQL Edition : $SQLEdition"`
				#"SQL Version : $SQLVersion / $Version "`
				#"SQL Server Collation : $SRVCollation"
				$hash = @{
					Instance = "$i (From Registry)"
					Label = "SQL Path"
					Value = $SQLPath
					}
				$Output = New-Object psobject -Property $hash
				$SQLInfo += $Output
				$hash = @{
					Instance = "$i (From Registry)"
					Label = "SQL Edition"
					Value = $SQLEdition
					}
				$Output = New-Object psobject -Property $hash
				$SQLInfo += $Output
				$hash = @{
					Instance = "$i (From Registry)"
					Label = "SQL Version"
					Value = "$SQLVersion / $Version"
					}
				$Output = New-Object psobject -Property $hash
				$SQLInfo += $Output
				$hash = @{
					Instance = "$i (From Registry)"
					Label = "SQL Server Collation"
					Value = $SRVCollation
					}
				$Output = New-Object psobject -Property $hash
				$SQLInfo += $Output
				}
			}
		}
	}
#End Sql Audit

#Perform DB Checks MKBRuntime Version
#If ($Service -eq "DB Servers") {
#31/03/16 MH - Added DB name to output
If (( get-service | ? {$_.displayname -match "SQL Server"})) {
    #Write-Host "MKBRuntime"
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null
	$MSQL = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer')#Place server name here in single quotes when connecting to another machine
	$MSQLInstance = $MSQL.serverinstances | % {$_.name}
	$MSQLInstances = @()
	ForEach ($Instance in $MSQLInstance) {
		$a = $MSQL.services | Where {$_.ServiceState -eq "Running" -and $_.displayname -eq "SQL Server ($instance)"}
		IF ($a)
			{$MSQLInstances += $Instance}
		Else
			{$MSQLInstancesReg += $Instance}
		}
	foreach ($Instance in $MSQLInstances) {
		$s = New-Object "Microsoft.SqlServer.Management.Smo.Server" .\$Instance
		#If (($s.availabilitygroups | where {$_.name -like "*AG1"}).localreplicarole -eq "Primary") {
		If (($s.availabilitygroups | where {$_.name -like "*AG1"}) -OR ($s.name -match "CR" -and $OSver -match "2008") -OR ($s.name -match "DB" -and $OSver -match "2012|2016|2019")) {
			$DBName = "MKBRuntime"
			$SqlConnection = New-Object System.Data.SqlClient.SqlConnection

			IF ($OSVer -match "2012|2016|2019") {$SqlConnection.ConnectionString = "Server=localhost;Database=$DBName;Integrated Security=True"}
			IF ($OSVer -match "2008") {$SqlConnection.ConnectionString = "Server=$Instance\$Instance;Database=$DBName;Integrated Security=True"}

			#$SqlConnection.ConnectionString = "Server=localhost;Database=$DBName;Integrated Security=True"

			$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
			$SqlCmd.CommandText = "select * from patching.release"
			$SqlCmd.Connection = $SqlConnection
			$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
			$SqlAdapter.SelectCommand = $SqlCmd
			$DataSet = New-Object System.Data.DataSet
			$Error.Clear()
			Try {
				$SqlAdapter.Fill($DataSet)
				$SqlConnection.Close()
				#$DBValue = (($dataset.tables[0].releasenumber |sort -unique)| measure -maximum).maximum
				$DBValue = (($dataset.tables[0]) | % {$_.releasenumber} | sort -unique | measure -Maximum).maximum
				$DBValue = "Release Number: $DBValue"
				$hash = @{
					Label = "$($SqlConnection.Database) - $Instance"
					Value = $DBValue
					}
				}
			Catch {
				$value = $Error[0]
				$DBValue = $value.exception.innerexception
				$hash = @{
					Label = $DBName
					Value = $DBValue.message
					}
				}
			$Output = New-Object psobject -Property $hash
			$DBChecks += $Output
			}
		}
	}
#End DB Checks

#App Services
#If ($Service -eq "APP Servers") {
If (( get-service | ? {$_.displayname -match "Emis|SDS"})) {
    #write-host "App Services"
	$ServiceArr = @()
	foreach ($AppService in $ALLServices) {
		IF (Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'" -ErrorAction Continue) {
			$a = Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'"
			$AService = $a.name
			$State = $a.state
			$Mode = $a.startmode
			$RunAs = $a.startname
			$ServiceArr += "$AService / $State / $Mode / $RunAs"
			$hash = @{
				Service = $a.name
				State = $a.state
				Mode = $a.startmode
				RunAs = $a.startname
				}
			$Output = New-Object psobject -Property $hash
			$AppServices += $Output
			}
		}
		#Write-Output $ServiceArr
	}
#End App Services

#App Service File Information
#If ($Service -eq "APP Servers") {
If (( get-service | ? {$_.displayname -match "Emis|SDS"})) {
    #Write-Host "App file service info"
	If (Test-Path "C:\ProgramData\sds\Version6\Applications\EmisWeb Services\*.exe") {
	    $Files = Get-ChildItem "C:\ProgramData\sds\Version6\Applications\EmisWeb Services\*.exe"
	    ForEach ($File in $Files) {
		    $FileVer = ($File | select -ExpandProperty VersionInfo).fileversion
		    $hash = @{
			    Filename = $File.FullName
			    FileVer = $FileVer
			    }
		    $Output = New-Object psobject -Property $hash
		    $AppFiles += $Output
		    }
        }
	If (Test-Path "C:\ProgramData\sds\Version6\Applications\EmisWeb Scheduler\*.exe") {
		$Files = Get-ChildItem "C:\ProgramData\sds\Version6\Applications\EmisWeb Scheduler\Emis.Scheduler.WindowsService.exe"
		ForEach ($File in $Files) {
			$FileVer = ($File | select -ExpandProperty VersionInfo).fileversion
			$hash = @{
				Filename = $File.FullName
				FileVer = $FileVer
				}
			$Output = New-Object psobject -Property $hash
			$AppFiles += $Output
			}
		}
	If (Test-Path "C:\ProgramData\SDS\Version6\Applications\EMAS Server\*.exe") {
		$Files = Get-ChildItem "C:\ProgramData\SDS\Version6\Applications\EMAS Server\Emis.ExternalMessaging.WindowsCoreService.exe"
		ForEach ($File in $Files) {
			$FileVer = ($File | select -ExpandProperty VersionInfo).fileversion
			$hash = @{
				Filename = $File.FullName
				FileVer = $FileVer
				}
			$Output = New-Object psobject -Property $hash
			$AppFiles += $Output
			}
		}
    If (Test-Path "C:\ProgramData\sds\Version6\Applications\Emis Connect\*.exe") {
	    $Files = Get-ChildItem "C:\ProgramData\sds\Version6\Applications\Emis Connect\*Core.Host.exe"
	    ForEach ($File in $Files) {
		    $FileVer = ($File | select -ExpandProperty VersionInfo).fileversion
		    $hash = @{
			    Filename = $File.FullName
			    FileVer = $FileVer
			    }
		    $Output = New-Object psobject -Property $hash
		    $AppFiles += $Output
		    }
        }
	}
#End App Service File Information

#List DGs - Use SF Vxprint commands to list DGs and then list volumes within DG
#If ($Service -eq "DB Servers" -and $OSVer -match "2008") {
If ( get-service | ? {$_.displayname -match "Veritas Storage Agent"}) {
    #Write-Host "2008 SFW DGs"
	$DGs = vxprint -Gn
	foreach ($DG in $DGs) {
		$Vols = vxprint -g $DG -vn
		foreach ($Vol in $Vols) {
			$a = vxvol -g $DG volinfo $Vol | find /i "Size        :"
			$b = $a.split(":")
			$VolSize = ($b[1])/1gb
			#Write-Output $DG
			#Write-Output $Vol
			#Write-Output "$VolSize GB"
			$hash = @{
				Diskgroup = $DG
				Volume = $Vol
				Size = "$VolSize GB"
				}
			$Output = New-Object psobject -Property $hash
			$DGInfo += $Output
			}
		}
	}
#end DGs

#DB NetBackup Services
#If ($Service -eq "DB Servers") {
If (( get-service | ? {$_.displayname -match "NetBackup"})) {
    #Write-Host "netbackup"
	$NetBackupArr = @()
	$BackupServices = gwmi win32_service -Filter "Name like 'NetBackup%'"
	foreach ($BackupService in $BackupServices) {
		#IF (Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'" -ErrorAction Continue) {
			#$a = Get-WmiObject win32_service -ComputerName $HName  -Filter "name = '$Appservice'"
			$AService = $BackupService.name
			$State = $BackupService.state
			$Mode = $BackupService.startmode
			$RunAs = $BackupService.StartName
			$NetBackupArr += "$AService / $State / $Mode / $RunAs"
			$hash = @{
				Service = $BackupService.name
				State = $BackupService.state
				Mode = $BackupService.startmode
				RunAs = $BackupService.StartName
				}
			$Output = New-Object psobject -Property $hash
			$NetBackupServices += $Output
			#}
		}
		Write-Output $NetBackupArr
	}
#END DB NetBackup Services

#Check NetBackup Client Program Version
#If ($Service -eq "DB Servers") {
If (( get-service | ? {$_.displayname -match "NetBackup"})) {
    #Write-Host "netbackup versions"
	IF (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Veritas NetBackup Client") {
		$NetBackupTemp = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Veritas NetBackup Client" `
			|Select DisplayName, DisplayVersion, Publisher, InstallDate, HelpLink, UninstallString #`
			#| where {$_.displayname -like "*Symantec NetBackup Client*"}
		If ($NetBackuptemp) {
			$NetBackupProgramVersion = $NetBackupTemp.displayname
			$NetBackupProgramVersion += " : "
			$NetBackupProgramVersion += $NetBackupTemp.displayversion
			}
		$hash = @{
			Label = "NetBackup Client Program Product"
			Value = $NetBackupTemp.displayname
			}
		$Output = New-Object psobject -Property $hash
		$ProgramInfo += $Output
		$hash = @{
			Label = "NetBackup Client Program Version"
			Value = $NetBackupTemp.displayversion
			}
		$Output = New-Object psobject -Property $hash
		$ProgramInfo += $Output
		Write-Output $NetBackupProgramVersion
		}
	}
#End NetBackup Client Program Version

#Write-Host "disk info"
#get disk / drive information
<#
$disks = gwmi win32_logicaldisk -Filter "drivetype=3"
foreach ($Disk in $disks) {
	#$a = vxvol -g $DG volinfo $Vol | find /i "Size        :"
	$diskletter = $Disk.deviceid
	$disksize = [Math]::round(($disk.size)/1gb)
	$diskvol = $Disk.volumeName
	$FreeSpace = [Math]::round(($disk.FreeSpace)/1gb)
	#$VolSize = ($b[1])/1gb
	#Write-Output $DG
	#Write-Output $Vol
	#Write-Output "$VolSize GB"
	$hash = @{
		Device = $Diskletter
		Volume = $diskVol
		Size = "$diskSize GB"
		FreeSpace = "$FreeSpace GB"
		}
	$Output = New-Object psobject -Property $hash
	$DiskInfo += $Output
    } #>

$Volumes = Get-WmiObject Win32_Volume | Where { $_.drivetype -eq '3' -and $_.driveletter}
foreach ( $Volume in $Volumes ) {
    #$DiskLetter = $Volume.DriveLetter
	#$Label = $Volume.Label
	#$DiskSize = [Math]::round(($Volume.Capacity)/1GB)
    #$FreeSpace = [Math]::round(($Volume.FreeSpace)/1GB)
    #$BlockSize = (($Volume.BlockSize)/1024)
	$hash = @{
		Device = $Volume.DriveLetter
		Volume = $Volume.Label
		Size = "$([Math]::round(($Volume.Capacity)/1GB)) GB"
		FreeSpace = "$([Math]::round(($Volume.FreeSpace)/1GB)) GB"
        BlockSize = "$(($Volume.BlockSize)/1024)K"
		}
	$Output = New-Object psobject -Property $hash
	$DiskInfo += $Output
	}
#End get disk / drive information

#Write-Host "network test 1"
#Connection tests
#Need to place the following into an array
# If ($Domain -eq "EmisGha") {
#     $EmisGhaConTest = Test-Connection "EmisGha.gi" -Count 1 -ErrorAction SilentlyContinue
#     IF ($EmisGhaConTest) {
# 	    #Write-Output "Successful conection made to violet.local domain"
# 	    $hash = @{
# 		    Connection = "EmisGha.gi"
# 		    State = "Success"
# 		    IPAddress = $EmisGhaConTest.ipv4address.ipaddresstostring
# 		    }
# 	    $Output = New-Object psobject -Property $hash
# 	    $NetTest += $Output
# 	    }
#     Else {
#     #Write-Output "No conection made to violet.local domain"
# 	    $hash = @{
# 		    Connection = "EmisGha.gi"
# 		    State = "Failed"
# 		    IPAddress = $EmisGhaConTest.ipv4address.ipaddresstostring
# 		    }
# 	    $Output = New-Object psobject -Property $hash
# 	    $NetTest += $Output
# 	    }
#     }
# Else {
#     $WhiteConTest = Test-Connection "white.local" -Count 1 -ErrorAction SilentlyContinue
#     $EmishostingConTest = Test-Connection "EmisHosting.com" -Count 1 -ErrorAction SilentlyContinue

#     IF ($WhiteConTest) {
# 	    #Write-Output "Successful conection made to white.local domain"
# 		    $hash = @{
# 		    Connection = "white.local"
# 		    State = "Success"
# 		    IPAddress = $WhiteConTest.ipv4address.ipaddresstostring
# 		    }
# 	    $Output = New-Object psobject -Property $hash
# 	    $NetTest += $Output
# 	    }
#     Else {
# 	    #Write-Output "No conection made to white.local domain"
# 		    $hash = @{
# 		    Connection = "white.local"
# 		    State = "Failed"
# 		    IPAddress = $WhiteConTest.ipv4address.ipaddresstostring
# 		    }
# 	    $Output = New-Object psobject -Property $hash
# 	    $NetTest += $Output
# 	    }

#     IF ($EmishostingConTest) {
# 	    #Write-Output "Successful conection made to violet.local domain"
# 	    $hash = @{
# 		    Connection = "EmisHosting.com"
# 		    State = "Success"
# 		    IPAddress = $EmishostingConTest.ipv4address.ipaddresstostring
# 		    }
# 	    $Output = New-Object psobject -Property $hash
# 	    $NetTest += $Output
# 	    }
#     Else {
#     #Write-Output "No conection made to violet.local domain"
# 	    $hash = @{
# 		    Connection = "EmisHosting.com"
# 		    State = "Failed"
# 		    IPAddress = $EmishostingConTest.ipv4address.ipaddresstostring
# 		    }
# 	    $Output = New-Object psobject -Property $hash
# 	    $NetTest += $Output
# 	    }
#     }
#End Connection tests

If ($Service -eq "APP Servers") {
#13/05/22 - Changed below due to Emis.Dapi service appearing on DB servers
#If (( get-service | ? {$_.displayname -match "EMIS"})) {
#If (( get-service | ? {$_.displayname -match "EMIS|SDS"})) {
    #Write-Host "jetty tests"
	$PortTests = @()
	# (($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "Public"}).Site | ? {$_.name -eq "Primary"} | % {$_.port} | ForEach {
	# 	$PortTests += New-Object -TypeName PSObject  -Property @{
	# 		Label = "Public Primary"
	# 		IP = $_."#text"
	# 		Port = $_.name
	# 		}
	# 	}
	# (($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "Public"}).Site | ? {$_.name -eq "Failover"} | % {$_.port} | ForEach {
	# 	$PortTests += New-Object -TypeName PSObject  -Property @{
	# 		Label = "Public Failover"
	# 		IP = $_."#text"
	# 		Port = $_.name
	# 		}
	# 	}
	(($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "IndexEndpoints"}).Site | ? {$_.name -eq "Scheduler"} | % {$_.port} | ForEach {
		$PortTests += New-Object -TypeName PSObject  -Property @{
			Label = "Scheduler"
			IP = $_."#text"
			Port = $_.name
			}
		}
	(($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "IndexEndpoints"}).Site | ? {$_.name -eq "EmisWeb"} |% {$_.port} | ForEach {
		$PortTests += New-Object -TypeName PSObject  -Property @{
			Label = "EmisWeb"
			IP = $_."#text"
			Port = $_.name
			}
		}
	(($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "IndexEndpoints"}).Site | ? {$_.name -eq "EMAS"} |% {$_.port} | ForEach {
		$PortTests += New-Object -TypeName PSObject  -Property @{
			Label = "EMAS"
			IP = $_."#text"
			Port = $_.name
			}
		}
	(($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "IndexEndpoints"}).Site | ? {$_.name -eq "EmisConnect"} |% {$_.port} | ForEach {
		$PortTests += New-Object -TypeName PSObject  -Property @{
			Label = "EmisConnect"
			IP = $_."#text"
			Port = $_.name
			}
		}
	(($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "IndexEndpoints"}).Site | ? {$_.name -eq "GPES"} |% {$_.port} | ForEach {
		$PortTests += New-Object -TypeName PSObject  -Property @{
			Label = "GPES"
			IP = $_."#text"
			Port = $_.name
			}
		}
	(($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "IndexEndpoints"}).Site | ? {$_.name -eq "EmisConnectAPI"} |% {$_.port} | ForEach {
		$PortTests += New-Object -TypeName PSObject  -Property @{
			Label = "EmisConnectAPI"
			IP = $_."#text"
			Port = $_.name
			}
		}

	(($XMLFilePorts.portcheck.domain | ? {(get-wmiobject WIN32_ComputerSystem).name -match $_.id}).location | ? {$_.name -eq "Spine"}).Site | ? {$_.name -eq "All"} | % {$_.port} | ForEach {
		$PortTests += New-Object -TypeName PSObject  -Property @{
			Label = "Spine"
			IP = $_."#text"
			Port = $_.name
			}
		}
    If ($PortTests) {
		ForEach ($Test in $PortTests) {
			$Socket = New-Object Net.Sockets.TcpClient
			$Label = $Test.Label
			$Computer = $Test.IP
			$Port = $Test.Port
			#Write-Host $Computer "-" $Port
			$ErrorActionPreference = 'SilentlyContinue'
			$Socket.Connect($Computer, $Port)
			$ErrorActionPreference = 'Continue'
			# Determine if we are connected.
			if ($Socket.Connected) {
				"${Computer}: Port $Port is open"
				$Socket.Close()
				$hash = @{
					Connection = If ($Label -eq "Spine") {"Port $Port ($Label / $Computer)"} ELSE {"Port $Port ($Label)"}
					State = "Success"
					IPAddress = $Computer
					}
				$Output = New-Object psobject -Property $hash
				$NetTest += $Output
	       	}
			else {
				"${Computer}: Port $Port is closed or filtered"
				#$Socket.Close()
				$hash = @{
					Connection = If ($Label -eq "Spine") {"Port $Port ($Label / $Computer)"} ELSE {"Port $Port ($Label)"}
					State = "Failed"
					IPAddress = $Computer
					}
				$Output = New-Object psobject -Property $hash
				$NetTest += $Output
				}# Apparently resetting the variable between iterations is necessary.
			$Socket = $null
			#$Count++
			}
		}
	}
#End JetNexus Test

#Start Mobile Tests
$URL = (($XMLFileMobile.environments.environment) | ? {$_.server.name -match $HName}).URL.name
$MobileEnv = (($XMLFileMobile.environments.environment) | ? {$_.server.name -match $HName}).name

If ($URL) {
    #Write-Host "Mobile URL tests...."
    #Write-Host "URL: " $URL
    #Write-Host "Mobile Name: " $MobileEnv

    [net.httpWebRequest] $req = [net.webRequest]::create($url)
    $Req.timeout= "10000" #10 Seconds
    $req.method = "HEAD"
    Try{ [net.httpWebResponse] $res = $req.getresponse()
        $Response = $res.StatusCode
        $Res.Close()
        }
    Catch {
        $ErrorMessage = $Error[0].Exception.Message
        #Write-Host $ErrorMessage
        $Response = "No Connection"
        }
    $hash = @{
		Connection = "$URL"
		State = "$Response"
		Environment = $MobileEnv
		}
	$Output = New-Object psobject -Property $hash
	$MobileTest += $Output

    }
#End Mobile Tests

#Start Certificate Tests

#Write-Host "Certificates"

$Certificates = @()

$Certs = gci Cert:\LocalMachine\* -Recurse | ? {$_.Subject -match "EMIS|NHS|Zscaler" -and $_.Subject -notmatch "EMIS Hosting|C2012-OPS-CA|$($env:computername)"}

ForEach ($Item in $Certs) {
    If (Test-Path -path Variable:\DNSList) {Clear-Variable DNSList}
    $DNSListItem=$Item.DnsNameList.punycode
    If ($DNSListItem -is [array]) {
        #Write-Host "DNS Arrray"
        $DNSList=($DNSListItem | % {$_}) -join("</br>")
        }
    Else {$DnsList = $($Item.DnsNameList)}
    Switch ($Item.Issuer) {
        {$_ -match "CN="} {$Issuer=$Item.Issuer.replace("CN=","")}
        {$_ -match "," -and $_ -match "CN="} {$Issuer=($Item.Issuer.substring($Item.Issuer.indexof("CN=")) | % {$_.substring(0,$_.indexof(","))}).replace("CN=","")}
        Default {$Issuer=$Item.Issuer}
        }
    #Write-Host $Issuer
    $hash = @{
        Subject = $($Item.Subject)
        #Issuer = $(($Item.Issuer.substring($Item.Issuer.indexof("CN=")) | % {$_.substring(0,$_.indexof(","))}).replace("CN=",""))
        Issuer = $Issuer
        EndDate = $($Item.NotAfter)
        DNSName = $DnsList
        Path = $(($Item.PSParentPath).Split("\")[-1])
        }
    $Output = New-Object psobject -Property $hash
    $Certificates += $OutPut
    }

#End Certificate Tests

############Start: Host File Checks########################

#Added 18/02/22 - Pulls values from host file
    $Pattern = '^(?<IP>\d{1,3}(\.\d{1,3}){3})\s+(?<Host>.+)$'
    $Contents = Get-Content "$($env:SystemRoot)\System32\drivers\etc\hosts"
    $Contents | % {
        If ( $_ -match $Pattern ) {
            $hash = @{
                IPAddress = $Matches.IP
                HostRecord = $Matches.Host
                }
            $Output = New-Object psobject -Property $hash
            $HostFileInfo += $Output
            #Write-Host "Recourd Count $($HostFileInfo.count)"
            }
        }
        #Write-Host "Recourd Count $($HostFileInfo.count)"
#    }

############END: Host File Checks###################

############Start: Get SPNs from Service Account########################

#Added 22/2/22 - Get SPNs from SQL Service Account

If ( get-service | ? {$_.displayname -match "SQL Server"} ) {
    $SQLServices = gwmi win32_service -Filter "Name like 'MSSQL$%'"
    ForEach ( $SQLService in $SQLServices ) {
        $Results = @()
        $RunAs = $SQLService.StartName
        $Instance = $(($SQLService.Name).Split('\$')[1])
        #Write-Host "Account: $($RunAs)"
        #Write-Host "Instance: $($Instance)"

        $strDomain = $Runas.split("\")[0]
        $User = $Runas.split("\")[1]

        #Write-Host "Domain: $($StrDomain)"
        #Write-Host "User: $($User)"
        #$StrDomain = "GPLive"
        #$User = "SQLServiceGP20"
        #Go search for the account and return properties, inclusing SPNs
        $domainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $strDomain)
        $domainroot = ([System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($domainContext).Name).replace(".",", dc=")
        $ad = New-Object System.DirectoryServices.DirectoryEntry("LDAP://DC=$Domainroot",$cred.username,$cred.getNetworkCredential().password)
        #$ad = New-Object System.DirectoryServices.DirectoryEntry("LDAP://DC=$Domainroot")
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher($ad)
        $objSearcher.SearchRoot = $ad
        $objSearcher.Filter = ("(SamAccountName=$user)")

        #Write-Host "DomainContext: ..$($domainContext.Name).."
        #Write-Host "DomainRoot: ..$($domainroot).."
        #Write-Host "ad.DN: $($ad.distinguishedName)"
        #Write-Host "ad.Path: $($ad.path)"


        $Result = $objsearcher.findall()
        If ( $Result.Properties.serviceprincipalname.count -ge 1 ) {
            ForEach ( $SPN in $Result.Properties.serviceprincipalname ) {
                $Hash = @{
                    Instance = $Instance
                    ServiceAccount = $RunAs
                    SPN = $SPN
                    }
                $Output = New-Object psobject -Property $hash
                $SQLServiceSPNs += $Output
                }
            }
        Else {
            $Hash = @{
                Instance = $Instance
                ServiceAccount = $RunAs
                SPN = "None"
                }
            $Output = New-Object psobject -Property $hash
            $SQLServiceSPNs += $Output
            }
        }
    #$SQLServiceSPNs | % { Write-Host "Instance: $($_.Instance), SerivceAccount: $($_.ServiceAccount), SPN: $($_.SPN)" }
    }

############Start: Get SPNs from Service Account########################


#Write-Host "begin outputs"

#Output all information to html file

$strDate = get-date -format "dd MMMM yyyy HH:mm:ss"
$Output = @()

#Remove <!-- saved from url=(0016)http://localhost --> after testing complete--prevent allow scripts pop-up
$Output = @"
<!DOCTYPE html>
<!-- saved from url=(0016)http://localhost -->
<html>
 <Font Face=Arial>
 <head>
  <style type="text/css">
  <!--
  body{
  background-color: #dcdcdc;
  }
  html{
    margin:0;
    padding:0;
  }
  #header{

  }
  #main{

  }
  h1{
    width:100%;
    margin-left:0%;
    margin-right:0%;
    text-indent:15px;
    color:#3f3f3f;
  }
  h2{
    width:100%;
    margin-left:0%;
    margin-right:0%;
    text-indent:15px;
    color:#3f3f3f;
  }
  h3{
    color:#3f3f3f;
  }
  table{
    border-spacing: 0px;
    border-collapse: collapse;
    align: center;
	width: 90%;
  }
  th {
    text-align: center;
    font-weight: bold;
    padding: 2px;
    border: 2px solid #dcdcdc;
    background: #4a70aa;
    color: #eeeeee;
  }
  td {
    text-align: right;
    padding: 2px;
    border: 2px solid #dcdcdc;
    background: #b0c4de;
  }
  td.alt {
    text-align: right;
    padding: 2px;
    border: 2px solid #dcdcdc;
    background: #e3f0f7;
  }
  ul {
    list-style-type:none;
    text-align: center;
    padding:0;
    margin:0;
  }
  a:link,a:visited {
    text-decoration:none;
    display:block;
    width:120;
    color: #0099ff;
  }
  a:hover,a:active {
    background-color:#b0b0b0;
    color: #ffffff;
  }
  -->
  </style>

  <title>$HName Report</title>
 </head>
 <body>
  <div id="header">
   <h1>Patching Domain Report task C1</h1>
   <h2>Report Generated : $strDate</h2>
   <h2>Server : $HName.$DomainFQDN</h2>
  </div>
  <div id="main">
   <HR WIDTH=90% COLOR=#336699 SIZE=10 Align=center>



"@

#Output O/S Info  class="center" width=100%
$Output += @"
   <h3 style="text-align:center">Operating System Details</h3>
   <table width=90% align=center>
    <TH>Label<TH>Setting</TH></TH>

"@

$RowCount = 0
Foreach ($Result in $OSInfo) {
	$Label = $Result.Label
	$value = $Result.Value
	switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left">$Label</td>
    <td>$Value</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left">$Label</td>
    <td class="alt">$Value</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@
#End output O/S Info

#Output NIC Info
$Output += @"
   <h3 style="text-align:center">Network Information</h3>
   <table width=90% align=center>
   <TH>NIC Label<TH>IP Address<TH>Gateway<TH>Mask<TH>Status</TH></TH></TH></TH></TH>

"@

$RowCount = 0
Foreach ($Result in $NetworkInfo) {
	$Label = $Result.Label
	$value = $Result.Value
	$DG = $Result.DG
    $Mask = $Result.Mask
    $Status = $Result.Status
	switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left">$Label</td>
    <td>$Value</td>
    <td>$DG</td>
    <td>$Mask</td>
    <td>$Status</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left">$Label</td>
    <td class="alt">$Value</td>
    <td class="alt">$DG</td>
    <td class="alt">$Mask</td>
    <td class="alt">$Status</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@
#End output NIC Info

#Output DNS Info
$Output += @"
   <h3 style="text-align:center">DNS Server Search Setting</h3>
   <table width=90% align=center>
    <TH>NIC Label<TH>Order<TH>DNS Servers</TH></TH></TH>

"@

$RowCount = 0
Foreach ($Result in $DNSInfo) {
	$Label = $Result.Label
	$Order = $Result.Order
	$value = $Result.Value
	switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left">$Label</td>
    <td style="text-align:center">$Order</td>
    <td>$Value</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left">$Label</td>
    <td class="alt" style="text-align:center">$Order</td>
    <td class="alt">$Value</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@
#End output DNS Info

#Output Route Info
$Output += @"
   <h3 style="text-align:center">Network Route Information</h3>
   <table width=90% align=center>
    <TH>NIC Label<TH>Destination<TH>Gateway<TH>Mask</TH></TH></TH></TH>

"@

$RowCount = 0
Foreach ($Result in $RouteInfo) {
	$value = $Result.InterfaceName
    $Label = $Result.Destination
	$DG = $Result.NextHop
    $Mask = $Result.Mask
	switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left">$Value</td>
    <td>$Label</td>
    <td>$DG</td>
    <td>$Mask</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left">$Value</td>
    <td class="alt">$Label</td>
    <td class="alt">$DG</td>
    <td class="alt">$Mask</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@
#End output Route Info

#18/02/22 - Output Host File Info
$Output += @"
   <h3 style="text-align:center">Host File Records</h3>
   <table width=90% align=center>
    <TH>Address<TH>Hostname</TH></TH>

"@

$RowCount = 0
Foreach ($Result in $HostFileInfo) {
	$Address = $Result.IPAddress
    $HostName = $Result.HostRecord
    switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left">$Address</td>
    <td>$HostName</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left">$Address</td>
    <td class="alt">$HostName</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@
#End output Host File Info

#Output DataDog Service Information
If (( get-service | ? {$_.displayname -match "DataDog"}) -and $DataDogServices) {
	$Output += @"
	   <h3 style="text-align:center">DataDog Service Information</h3>
	   <table width=90% align=center>
	    <TH>Service<TH>Status<TH>Startup Mode<TH>Service User</TH></TH></TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $DataDogServices) {
		$ServiceName = $Result.Service
		$State = $Result.State
		$Mode = $Result.Mode
		$RunAs = $result.RunAs
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
	    <tr>
	    <td style="text-align:left">$ServiceName</td>
        <td style="text-align:center">$State</td>
        <td>$Mode</td>
	    <td>$RunAs</td>
	    </tr>

"@
			}
		else {
		   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$ServiceName</td>
	    <td class="alt" style="text-align:center">$State</td>
	    <td class="alt">$Mode</td>
	    <td class="alt">$RunAs</td>
	    </tr>


"@
			}
		$RowCount++
	}

	$Output += @"
	   </table>


"@
}
#End output DataDog Service Information

#Output AV Info
$Output += @"
   <h3 style="text-align:center">Anti-Virus Information</h3>
   <table width=90% align=center>
    <TH>Label<TH>Version</TH></TH>

"@

$RowCount = 0
Foreach ($Result in $AntiVirus) {
	$Label = $Result.Label
	$value = $Result.Value
	switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left">$Label</td>
    <td>$Value</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left">$Label</td>
    <td class="alt">$Value</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@
#End output AV Info

#Output Software Info
#If (($Service -eq "DB Servers") -or ($Service -eq "App Servers")) {
If (( get-service | ? {$_.displayname -match "SQL Server"}) -or ( get-service | ? {$_.displayname -match "EMIS|SDS"})) {
	$Output += @"
	   <h3 style="text-align:center">Software Information</h3>
	   <table width=90% align=center>
	    <TH>Program<TH>Version</TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $ProgramInfo) {
		$Label = $Result.Label
		$value = $Result.Value
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
	    <tr>
	    <td style="text-align:left">$Label</td>
	    <td>$Value</td>
	    </tr>

"@
			}
		else {
		   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$Label</td>
	    <td class="alt">$Value</td>
	    </tr>


"@
			}
		$RowCount++
	}

	$Output += @"
	   </table>


"@
}
#End output Software Info#Output NetBackup Service Information

#Output vRops Service details
#If ($Service -eq "DB Servers" -and $TelegrafServices) {
#If (( get-service | ? {$_.displayname -match "telegraf"}) -and $MonitoringServices) {
If (( get-service | ? {$_.displayname -match "telegraf" -or $_.DisplayName -match "Log Insight"}) -and $MonitoringServices) {
	$Output += @"
	   <h3 style="text-align:center">Monitoring Service Information</h3>
	   <table width=90% align=center>
	    <TH>Service<TH>Status<TH>Startup Mode<TH>Service User</TH></TH></TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $MonitoringServices) {
		$ServiceName = $Result.Service
		$State = $Result.State
		$Mode = $Result.Mode
		$RunAs = $result.RunAs
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
	    <tr>
	    <td style="text-align:left">$ServiceName</td>
        <td style="text-align:center">$State</td>
        <td>$Mode</td>
	    <td>$RunAs</td>
	    </tr>

"@
			}
		else {
		   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$ServiceName</td>
	    <td class="alt" style="text-align:center">$State</td>
	    <td class="alt">$Mode</td>
	    <td class="alt">$RunAs</td>
	    </tr>


"@
			}
		$RowCount++
	}

	$Output += @"
	   </table>


"@
}
#End output vRops Service Information

#Output SQL Info
$CurrentInstance = $null
$RowCount = 0
$Count = 0

#If ($Service -eq "DB Servers") {
If (( get-service | ? {$_.displayname -match "SQL Server"})) {


	Foreach ($Result in $SQLInfo) {
		$Instance = $Result.Instance
		$Label = $Result.Label
		$value = $Result.Value
			IF ($CurrentInstance -ne $Instance){
				If ($Count -ne 0) {
					$Output += @"
     </Table>

"@
}
		$RowCount = 0
		$Output += @"
	   <h3 style="text-align:center">SQL Information $Instance</h3>
	   <table width=90% align=center>
	    <TH>Setting<TH>Value</TH></TH>

"@

	}

			$CurrentInstance = $Instance
			switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
				}
			If ($Row -eq "Even") {
				$Output += @"
	    <tr>
	    <td style="text-align:left">$Label</td>
	    <td>$Value</td>
	    </tr>

"@
				}
			else {
		  		$Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$Label</td>
	    <td class="alt">$Value</td>
	    </tr>


"@
				}
			$Count++
			$RowCount++
		}

		$Output += @"
	   </table>


"@
	}
#End output SQL Info

###??????
$CurrentInstance = $null
$RowCount = 0
$Count = 0


#Output SQL Access
#If ($Service -eq "DB Servers") {
If (( get-service | ? {$_.displayname -match "SQL Server"})) {

	Foreach ($Result in $SQLServerAccess) {
		$Instance = $Result.Instance
		$Label = $Result.Label
		$Value = $Result.Value
			IF ($CurrentInstance -ne $Instance){
				If ($Count -ne 0) {
					$Output += @"
     </Table>

"@
}
		$RowCount = 0
		$Output += @"
	   <h3 style="text-align:center">SQL Access $Instance</h3>
	   <table width=90% align=center>
	    <TH>Role<TH>Group / User</TH></TH>

"@

	}

			$CurrentInstance = $Instance
			switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
				}
			If ($Row -eq "Even") {
				$Output += @"
	    <tr>
	    <td style="text-align:left">$Label</td>
	    <td>$Value</td>
	    </tr>

"@
				}
			else {
		  		$Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$Label</td>
	    <td class="alt">$Value</td>
	    </tr>


"@
				}
			$Count++
			$RowCount++
		}

		$Output += @"
	   </table>


"@
	}
#End SQL Access

#Output SQL Logins
#If ($Service -eq "DB Servers") {
If (( get-service | ? {$_.displayname -match "SQL Server"})) {
	$CurrentInstance = $null
	Foreach ($Result in $SQLLogins) {
		$Instance = $Result.Instance
		$Label = $Result.Label
		$Value = $Result.Value
			IF ($CurrentInstance -ne $Instance){
				If ($Count -ne 0) {
					$Output += @"
     </Table>

"@
}
		$RowCount = 0
		$Output += @"
	   <h3 style="text-align:center">SQL Logins $Instance</h3>
	   <table width=90% align=center>
	    <TH>Type<TH>Name</TH></TH>

"@

	}

			$CurrentInstance = $Instance
			switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
				}
			If ($Row -eq "Even") {
				$Output += @"
	    <tr>
	    <td style="text-align:left">$Label</td>
	    <td>$Value</td>
	    </tr>

"@
				}
			else {
		  		$Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$Label</td>
	    <td class="alt">$Value</td>
	    </tr>


"@
				}
			$Count++
			$RowCount++
		}

		$Output += @"
	   </table>


"@
	}
#End SQL Logins

#Output SQL Service SPN Info
If (( get-service | ? {$_.displayname -match "SQL Server"}) -and ($SQLServiceSPNs)) {
	$Output += @"
   <h3 style="text-align:center">SQL Service SPN Check</h3>
   <table width=90% align=center>
    <TH>Instance<TH>Service Account<TH>Service Principal Name</TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $SQLServiceSPNs) {
		$Instance = $Result.Instance
		$ServiceAccount = $Result.ServiceAccount
		$SPN = $Result.SPN
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
    <tr>
    <td style="text-align:left">$Instance</td>
    <td style="text-align:center">$ServiceAccount</td>
    <td>$SPN</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left">$Instance</td>
    <td class="alt" style="text-align:center">$ServiceAccount</td>
    <td class="alt">$SPN</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@
	}
#End output SQL Service SPNs

#Output DBCheck Info
#If (($Service -eq "DB Servers") -and ($DBChecks)) {
#If ($Service -eq "DB Servers") {
If (( get-service | ? {$_.displayname -match "SQL Server"}) -and ($DBChecks)) {
	$Output += @"
   <h3 style="text-align:center">Database Version Checks</h3>
   <table width=90% align=center>
    <TH>Database<TH>Value</TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $DBChecks) {
		$Label = $Result.Label
		$value = $Result.Value
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
    <tr>
    <td style="text-align:left">$Label</td>
    <td>$Value</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left">$Label</td>
    <td class="alt">$Value</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@
	}
#End output DBChecks

#Output App Service Information
#If ($Service -eq "APP Servers") {
If (( get-service | ? {$_.displayname -match "EMIS|SDS"})) {
	$Output += @"
	   <h3 style="text-align:center">Application Service Information</h3>
	   <table width=90% align=center>
	    <TH>Service<TH>Status<TH>Startup Mode<TH>Service User</TH></TH></TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $AppServices) {
		$ServiceName = $Result.Service
		$State = $Result.State
		$Mode = $Result.Mode
		$RunAs = $Result.RunAs
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
	    <tr>
	    <td style="text-align:left">$ServiceName</td>
        <td style="text-align:center">$State</td>
        <td>$Mode</td>
	    <td>$RunAs</td>
	    </tr>

"@
			}
		else {
		   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$ServiceName</td>
	    <td class="alt" style="text-align:center">$State</td>
	    <td class="alt">$Mode</td>
	    <td class="alt">$RunAs</td>
	    </tr>


"@
			}
		$RowCount++
	}

	$Output += @"
	   </table>


"@
}
#End output App Service Information

#Output App Service File Information
#If ($Service -eq "APP Servers") {
If (( get-service | ? {$_.displayname -match "EMIS|SDS"})) {
	$Output += @"
	   <h3 style="text-align:center">Application Service File Versioning</h3>
	   <table width=90% align=center>
	    <TH>File Name<TH>Version</TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $AppFiles) {
		$FileName = $Result.FileName
		$FileVer = $Result.FileVer
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
	    <tr>
	    <td style="text-align:left">$FileName</td>
        <td>$FileVer</td>
	    </tr>

"@
			}
		else {
		   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$FileName</td>
	    <td class="alt">$FileVer</td>
	    </tr>


"@
			}
		$RowCount++
	}

	$Output += @"
	   </table>


"@
}
#End output App Service File Information

#Output Cluster Service Information
#If ($Service -eq "DB Servers" -and $OSVer -match "2012" -and ((Get-WindowsFeature | ? {$_.name -match "Failover-Clustering"}).installed -eq $True) ) {
If (( ( get-service | ? {$_.displayname -match "Cluster Service"}).status -eq "Running" ) -and $OSVer -match "2012|2016|2019") {
	$Output += @"
	   <h3 style="text-align:center">Cluster Information</h3>
	   <table width=90% align=center>
	    <TH>Label<TH>Setting</TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $ClusterInfo) {
		$Label = $Result.Label
		$Value = $Result.Value
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
	    <tr>
	    <td style="text-align:left">$Label</td>
        <td>$Value</td>
	    </tr>

"@
			}
		else {
		   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$Label</td>
	    <td class="alt">$Value</td>
	    </tr>


"@
			}
		$RowCount++
	}

	$Output += @"
	   </table>


"@
}
#End output Cluster Service Information

#Output NetBackup Service Information
#If ($Service -eq "DB Servers" -and $NetBackupServices) {
If (( get-service | ? {$_.displayname -match "NetBackup"}) -and $NetBackupServices) {
	$Output += @"
	   <h3 style="text-align:center">NetBackup Service Information</h3>
	   <table width=90% align=center>
	    <TH>Service<TH>Status<TH>Startup Mode<TH>Service User</TH></TH></TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $NetBackupServices) {
		$ServiceName = $Result.Service
		$State = $Result.State
		$Mode = $Result.Mode
		$RunAs = $result.RunAs
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
	    <tr>
	    <td style="text-align:left">$ServiceName</td>
        <td style="text-align:center">$State</td>
        <td>$Mode</td>
	    <td>$RunAs</td>
	    </tr>

"@
			}
		else {
		   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$ServiceName</td>
	    <td class="alt" style="text-align:center">$State</td>
	    <td class="alt">$Mode</td>
	    <td class="alt">$RunAs</td>
	    </tr>


"@
			}
		$RowCount++
	}

	$Output += @"
	   </table>


"@
}
#End output NetBackup Service Information

#Output Diskgroup Info
$CurrentDG = $null
$RowCount = 0
$Count = 0


#If ($Service -eq "DB Servers" -and $OSVer -match "2008") {
If ( get-service | ? {$_.displayname -match "Veritas Storage Agent"}) {


	Foreach ($Result in $DGInfo) {
		$DG = $Result.Diskgroup
		$Volume = $Result.Volume
		$Size = $Result.Size
			IF ($CurrentDG -ne $DG){
				If ($Count -ne 0) {
					$Output += @"
     </Table>

"@
}
		$RowCount = 0
		$Output += @"
	   <h3 style="text-align:center">Diskgroup $DG</h3>
	   <table width=90% align=center>
	    <TH>Volume<TH>Size</TH></TH>

"@

	}

			$CurrentDG = $DG
			switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
				}
			If ($Row -eq "Even") {
				$Output += @"
	    <tr>
	    <td style="text-align:left">$Volume</td>
	    <td>$Size</td>
	    </tr>

"@
				}
			else {
		  		$Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$Volume</td>
	    <td class="alt">$Size</td>
	    </tr>


"@
				}
			$Count++
			$RowCount++
		}

		$Output += @"
	   </table>


"@
	}
#End output Diskgroup Info

#Output Disk Info
#If ($Service -eq "APP Servers") {
	$Output += @"
	   <h3 style="text-align:center">Disk Information</h3>
	   <table width=90% align=center>
	    <TH>Letter<TH>Volume<TH>Size<TH>Free Space<TH>Block Size</TH></TH></TH></TH></TH>

"@

	$RowCount = 0
	Foreach ($Result in $DiskInfo) {
		$Letter = $Result.Device
		$Volume = $Result.Volume
		$Size = $Result.Size
		$FreeSpace = $Result.Freespace
        $BlockSize = $Result.BlockSize
		switch ($RowCount) {
		  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
		  		{ $_ % 2 -eq 0 } {$Row = "Even" }
			}
		If ($Row -eq "Even") {
			$Output += @"
	    <tr>
	    <td style="text-align:left">$Letter</td>
        <td style="text-align:left">$Volume</td>
        <td>$Size</td>
        <td>$FreeSpace</td>
	    <td>$BlockSize</td>
	    </tr>

"@
			}
		else {
		   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$Letter</td>
        <td class="alt" style="text-align:left">$Volume</td>
        <td class="alt">$Size</td>
        <td class="alt">$FreeSpace</td>
	    <td class="alt">$BlockSize</td>
	    </tr>


"@
			}
		$RowCount++
	}

	$Output += @"
	   </table>


"@
#}
#End output Disk Info

<#
$Output += @"

  </div>
 </body>
</html>


"@
#>
#End

#Output Network Connection Info
$Output += @"
	   <h3 style="text-align:center">Network Connection Test</h3>
	   <table width=90% align=center>
	    <TH>Connection<TH>State<TH>IP Address</TH></TH></TH>

"@

$RowCount = 0
Foreach ($Result in $NetTest) {
	$Conn = $Result.Connection
	$State = $Result.State
	$IP = $Result.IPAddress
	switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
	If ($Row -eq "Even") {
		$Output += @"
	    <tr>
	    <td style="text-align:left">$Conn</td>
        <td style="text-align:center">$State</td>
        <td>$IP</td>
	    </tr>

"@
			}
	else {
	   $Output += @"
	    <tr>
	    <td class="alt" style="text-align:left">$Conn</td>
	    <td class="alt" style="text-align:center">$State</td>
	    <td class="alt">$IP</td>
	    </tr>


"@
		}
	$RowCount++
}

$Output += @"
	   </table>


"@

#End network test

#Output Mobile Connection Info

IF ($MobileTest) {
    $Output += @"
	       <h3 style="text-align:center">Mobile Connection Test</h3>
	       <table width=90% align=center>
	        <TH>Connection<TH>State<TH>Environment</TH></TH></TH>

"@

    $RowCount = 0
    Foreach ($Result in $MobileTest) {
	    $Conn = $Result.Connection
	    $State = $Result.State
	    $IP = $Result.Environment
	    switch ($RowCount) {
	  		    { $_ % 2 -eq 1 } {$Row = "Odd" }
	  		    { $_ % 2 -eq 0 } {$Row = "Even" }
		    }
	    If ($Row -eq "Even") {
		    $Output += @"
	        <tr>
	        <td style="text-align:left">$Conn</td>
            <td style="text-align:center">$State</td>
            <td>$IP</td>
	        </tr>

"@
			}
	    else {
	       $Output += @"
	        <tr>
	        <td class="alt" style="text-align:left">$Conn</td>
	        <td class="alt" style="text-align:center">$State</td>
	        <td class="alt">$IP</td>
	        </tr>


"@
		    }
	    $RowCount++
    }

    $Output += @"
	       </table>


"@

    }
#End Mobile test

#Start Certificate Output

IF ($Certificates) {
    $Output += @"
	       <h3 style="text-align:center">Certificate Test</h3>
	       <table width=90% align=center>
	       <TH>Dns Name<TH>Issuer<TH>End Date<TH>Path</TH></TH></TH></TH>

"@

    $RowCount = 0
    Foreach ($Result in $Certificates) {
	    $Subject = $Result.Subject
	    $Issuer = $Result.Issuer
	    $EndDate = $Result.EndDate
	    $DNSName = $Result.DNSName
	    $Path = $Result.Path
	    switch ($RowCount) {
	  		    { $_ % 2 -eq 1 } {$Row = "Odd" }
	  		    { $_ % 2 -eq 0 } {$Row = "Even" }
		    }
	    If ($Row -eq "Even") {
		    $Output += @"
	        <tr>
	        <td style="text-align:left">$DNSName</td>
            <td style="text-align:left">$Issuer</td>
            <td style="text-align:left">$EndDate</td>
            <td style="text-align:center">$Path</td>
            </tr>

"@
			}
	    else {
	       $Output += @"
	        <tr>
	        <td class="alt" style="text-align:Left">$DNSName</td>
	        <td class="alt" style="text-align:Left">$Issuer</td>
	        <td class="alt" style="text-align:Left">$EndDate</td>
	        <td class="alt" style="text-align:center">$Path</td>
	        </tr>


"@
		    }
	    $RowCount++
    }

    $Output += @"
	       </table>


"@

    }
#End Certificate Output

$Output += @"

  </div>
 </body>
</html>


"@

#End

#test whether C:\Emis path exists

#IF (-not (Test-Path "C:\Emis")) { New-Item -Path "C:\Emis" -ItemType Directory}
IF (-not (Test-Path "$($ScriptPath)\Result")) { New-Item -Path "$($ScriptPath)\Result" -ItemType Directory}

Out-File -Filepath "$($ScriptPath)\Result\$HName.Host-Report.html" -InputObject $Output

$XMLOutFile = @()

$File = "$($ScriptPath)\Result\$HName.Host-Report.xml"

$XmlWriter = New-Object System.XMl.XmlTextWriter($File,$Null)

# choose a pretty formatting:
$xmlWriter.Formatting = 'Indented'
$xmlWriter.Indentation = 1
$XmlWriter.IndentChar = "`t"

# write the header
$xmlWriter.WriteStartDocument()

# set XSL statements
$xmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")

# create root element "machines" and add some attributes to it
$comment = 'Server = $($HName)'
$XmlWriter.WriteComment($Comment)
$xmlWriter.WriteStartElement('Server')
$XmlWriter.WriteAttributeString('name', $HName)
$XmlWriter.WriteAttributeString('date', $StrDate)
$XmlWriter.WriteAttributeString('Domain', $DomainName)
$XmlWriter.WriteAttributeString('FQDN', $DomainFQDN) #Added 08-06-2023
$XmlWriter.WriteAttributeString('OU', $ComputerOU ) #Added 08-06-2023

#Create Node for osInformation
$XmlWriter.WriteComment('Operating System Details')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'osInfo')

ForEach ($Item in $osInfo) {
    $xmlWriter.WriteStartElement('Property')
    $XmlWriter.WriteAttributeString('Name', $($Item.Label))
    $XmlWriter.WriteString($($Item.Value))
    $xmlWriter.WriteEndElement()
    }
# close the "osinfo" node:
$xmlWriter.WriteEndElement()

#Create Node for NetworkInfo
$XmlWriter.WriteComment('NetWork Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'NetworkInfo')

ForEach ($Item in $NetworkInfo) {
    $xmlWriter.WriteStartElement('NIC')
    $XmlWriter.WriteAttributeString('IP', $($Item.value))
    $xmlWriter.WriteElementString('NicLabel', $($Item.Label))
    $xmlWriter.WriteElementString('Gateway', $($Item.DG))
    $xmlWriter.WriteElementString('Mask', $($Item.Mask))
    $xmlWriter.WriteElementString('Status', $($Item.Status))
    $xmlWriter.WriteEndElement()
    }
# close the "NetworkInfo" node:
$xmlWriter.WriteEndElement()

#Create Node for DNSInfo
$XmlWriter.WriteComment('DNS Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'DNSInfo')

ForEach ($Item in $DNSInfo) {
    $xmlWriter.WriteStartElement('DNS')
    $XmlWriter.WriteAttributeString('Order', $($Item.order))
    $xmlWriter.WriteElementString('NicLabel', $($Item.Label))
    $xmlWriter.WriteElementString('DNSServer', $($Item.value))
    $xmlWriter.WriteEndElement()
    }
# close the "DNSInfo" node:
$xmlWriter.WriteEndElement()

#Create Node for RouteInfo
$XmlWriter.WriteComment('NetWork Route Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'RouteInfo')

ForEach ($Item in $RouteInfo) {
    $xmlWriter.WriteStartElement('Route')
    $XmlWriter.WriteAttributeString('Destination', $($Item.Destination))
    $xmlWriter.WriteElementString('NicLabel', $($Item.InterFaceName))
    $xmlWriter.WriteElementString('Gateway', $($Item.NextHop))
    $xmlWriter.WriteElementString('Mask', $($Item.Mask))
    $xmlWriter.WriteEndElement()
    }
# close the "RouteInfo" node:
$xmlWriter.WriteEndElement()

#Create Node for Host File
$XmlWriter.WriteComment('Host File Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'HostFileInfo')

ForEach ($Item in $HostFileInfo) {
    $xmlWriter.WriteStartElement('HostFile')
    $XmlWriter.WriteAttributeString('IPAddress', $($Item.IPAddress))
    $xmlWriter.WriteElementString('HostRecord', $($Item.HostRecord))
    $xmlWriter.WriteEndElement()
    }
# close the "Host File" node:
$xmlWriter.WriteEndElement()

#Create Node for DataDogServices
$XmlWriter.WriteComment('DataDog Services')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'DataDogServices')

ForEach ($Item in $DataDogServices) {
    $xmlWriter.WriteStartElement('Service')
    $XmlWriter.WriteAttributeString('Name', $($Item.Service))
    $xmlWriter.WriteElementString('State', $($Item.State))
    $xmlWriter.WriteElementString('Startup', $($Item.Mode))
    $xmlWriter.WriteElementString('RunAs', $($Item.RunAs))
    $xmlWriter.WriteEndElement()
    }
# close the "DataDogServices" node:
$xmlWriter.WriteEndElement()

#Create Node for AntiVirusInformation
$XmlWriter.WriteComment('AntiVirus Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'AntiVirus')

ForEach ($Item in $AntiVirus) {
    $xmlWriter.WriteStartElement('Property')
    $XmlWriter.WriteAttributeString('Name', $($Item.Label))
    $XmlWriter.WriteRaw($($Item.Value))
    $xmlWriter.WriteEndElement()
    }
# close the "AntiVirus" node:
$xmlWriter.WriteEndElement()

#Create Node for MonitoringServices
$XmlWriter.WriteComment('Monitoring Services')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'MonitoringServices')

ForEach ($Item in $MonitoringServices) {
    $xmlWriter.WriteStartElement('Service')
    $XmlWriter.WriteAttributeString('Name', $($Item.Service))
    $xmlWriter.WriteElementString('State', $($Item.State))
    $xmlWriter.WriteElementString('Startup', $($Item.Mode))
    $xmlWriter.WriteElementString('RunAs', $($Item.RunAs))
    $xmlWriter.WriteEndElement()
    }
# close the "MonitoringServices" node:
$xmlWriter.WriteEndElement()

#Create Node for ProgramInformation
$XmlWriter.WriteComment('Program Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'ProgramInfo')

ForEach ($Item in $ProgramInfo) {
    $xmlWriter.WriteStartElement('Property')
    $XmlWriter.WriteAttributeString('Name', $($Item.Label))
    $XmlWriter.WriteRaw($($Item.Value))
    $xmlWriter.WriteEndElement()
    }
# close the "ProgramInfo" node:
$xmlWriter.WriteEndElement()

#Create Node for SQLInfo
$XmlWriter.WriteComment('SQL Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'SQLInfo')
$CurrentInstance = $Null
$Count = 0
IF($SQLinfo) {
    ForEach ($Item in $SQLInfo) {
        $Instance = $Item.Instance
        #Write-Host "CurrentInstance: $CurrentInstance"
        #Write-Host "Instance: $Instance"
        If ($CurrentInstance -ne $instance -and $Count -eq 0) {
            #Write-Host "First Instance"
            $xmlWriter.WriteStartElement('SQLInstanceInfo')
            $XmlWriter.WriteAttributeString('Instance', $($Item.Instance))
            }
        ElseIf ($CurrentInstance -ne $instance) {
            #Write-Host "Next Instance"
            $xmlWriter.WriteEndElement()
            $xmlWriter.WriteStartElement('SQLInstanceInfo')
            $XmlWriter.WriteAttributeString('Instance', $($Item.Instance))
            }
        $xmlWriter.WriteStartElement('Property')
        $xmlWriter.WriteAttributeString('Setting', $($Item.Label))
        $xmlWriter.WriteRaw($($Item.Value))
        $xmlWriter.WriteEndElement()
        $CurrentInstance = $Instance
        $Count++
        }
    # close the "SQLInstance" node:
    $xmlWriter.WriteEndElement()
    }
# close the "SQLInfo" node:
$xmlWriter.WriteEndElement()

#Create Node for SQLAccess
$XmlWriter.WriteComment('SQL Access')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'SQLAccess')
$CurrentInstance = $Null
$Count = 0
IF($SQLServerAccess) {
    ForEach ($Item in $SQLServerAccess) {
        $Instance = $Item.Instance
        #Write-Host "CurrentInstance: $CurrentInstance"
        #Write-Host "Instance: $Instance"
        If ($CurrentInstance -ne $instance -and $Count -eq 0) {
            #Write-Host "First Instance"
            $xmlWriter.WriteStartElement('SQLAccessInfo')
            $XmlWriter.WriteAttributeString('Instance', $($Item.Instance))
            }
        ElseIf ($CurrentInstance -ne $instance) {
            #Write-Host "Next Instance"
            $xmlWriter.WriteEndElement()
            $xmlWriter.WriteStartElement('SQLAccessInfo')
            $XmlWriter.WriteAttributeString('Instance', $($Item.Instance))
            }
        $xmlWriter.WriteStartElement('Property')
        $xmlWriter.WriteAttributeString('Role', $($Item.Label))
        $xmlWriter.WriteRaw($($Item.Value))
        $xmlWriter.WriteEndElement()
        $CurrentInstance = $Instance
        $Count++
        }
    # close the "SQLAccess" node:
    $xmlWriter.WriteEndElement()
    }
# close the "SQLInfo" node:
$xmlWriter.WriteEndElement()

#Create Node for SQLLogins
$XmlWriter.WriteComment('SQL Logins')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'SQLLogins')
$CurrentInstance = $Null
$Count = 0
IF($SQLLogins) {
    ForEach ($Item in $SQLLogins) {
        $Instance = $Item.Instance
        #Write-Host "CurrentInstance: $CurrentInstance"
        #Write-Host "Instance: $Instance"
        If ($CurrentInstance -ne $instance -and $Count -eq 0) {
            #Write-Host "First Instance"
            $xmlWriter.WriteStartElement('SQLLoginInfo')
            $XmlWriter.WriteAttributeString('Instance', $($Item.Instance))
            }
        ElseIf ($CurrentInstance -ne $instance) {
            #Write-Host "Next Instance"
            $xmlWriter.WriteEndElement()
            $xmlWriter.WriteStartElement('SQLLoginInfo')
            $XmlWriter.WriteAttributeString('Instance', $($Item.Instance))
            }
        $xmlWriter.WriteStartElement('Property')
        $xmlWriter.WriteAttributeString('Type', $($Item.Label))
        $xmlWriter.WriteRaw($($Item.Value))
        $xmlWriter.WriteEndElement()
        $CurrentInstance = $Instance
        $Count++
        }
    # close the "SQLAccess" node:
    $xmlWriter.WriteEndElement()
    }
# close the "SQLInfo" node:
$xmlWriter.WriteEndElement()

#Create Node for SQL Service SPNs
$XmlWriter.WriteComment('SQL Service SPN Checks')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'SQLServiceSPNs')

ForEach ($Item in $SQLServiceSPNs) {
    $xmlWriter.WriteStartElement('SQLServiceSPN')
    $XmlWriter.WriteAttributeString('SPN', $($Item.SPN))
    #$xmlWriter.WriteStartElement('ServiceAccount')
    #$XmlWriter.WriteAttributeString('ServiceAccount', $($Item.ServiceAccount))
    $XmlWriter.WriteElementString('Instance', $($Item.Instance))
    $XmlWriter.WriteElementString('ServiceAccount', $($Item.ServiceAccount))
    #$XmlWriter.WriteElementString('SPN', $($Item.SPN))
    $xmlWriter.WriteEndElement()
    }
# close the "SQL Service SPNs" node:
$xmlWriter.WriteEndElement()


#Create Node for DB Checks
$XmlWriter.WriteComment('Database Version Checks')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'DBChecks')

ForEach ($Item in $DBChecks) {
    $xmlWriter.WriteStartElement('Property')
    $XmlWriter.WriteAttributeString('Name', $($Item.Label))
    $XmlWriter.WriteRaw($($Item.Value))
    $xmlWriter.WriteEndElement()
    }
# close the "DB Checks" node:
$xmlWriter.WriteEndElement()

#Create Node for AppServices
$XmlWriter.WriteComment('Application Services')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'AppServices')

ForEach ($Item in $AppServices) {
    $xmlWriter.WriteStartElement('Service')
    $XmlWriter.WriteAttributeString('Name', $($Item.Service))
    $xmlWriter.WriteElementString('State', $($Item.State))
    $xmlWriter.WriteElementString('Startup', $($Item.Mode))
    $xmlWriter.WriteElementString('RunAs', $($Item.RunAs))
    $xmlWriter.WriteEndElement()
    }
# close the "AppServices" node:
$xmlWriter.WriteEndElement()

#Create Node for AppFiles
$XmlWriter.WriteComment('Application File Versions')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'AppFiles')

ForEach ($Item in $AppFiles) {
    $xmlWriter.WriteStartElement('Property')
    $XmlWriter.WriteAttributeString('Name', $($Item.FileName))
    $XmlWriter.WriteRaw($($Item.FileVer))
    $xmlWriter.WriteEndElement()
    }
# close the "AppFiles" node:
$xmlWriter.WriteEndElement()

#Create Node for ClusterInformation
$XmlWriter.WriteComment('Cluster Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'ClusterInfo')

ForEach ($Item in $ClusterInfo) {
    $xmlWriter.WriteStartElement('Property')
    $XmlWriter.WriteAttributeString('Name', $($Item.Label))
    $XmlWriter.WriteRaw($($Item.Value))
    $xmlWriter.WriteEndElement()
    }
# close the "Clusterinfo" node:
$xmlWriter.WriteEndElement()

#Create Node for NetBackupServices
$XmlWriter.WriteComment('NetBackup Services')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'NetBackupServices')

ForEach ($Item in $NetBackupServices) {
    $xmlWriter.WriteStartElement('Service')
    $XmlWriter.WriteAttributeString('Name', $($Item.Service))
    $xmlWriter.WriteElementString('State', $($Item.State))
    $xmlWriter.WriteElementString('Startup', $($Item.Mode))
    $xmlWriter.WriteElementString('RunAs', $($Item.RunAs))
    $xmlWriter.WriteEndElement()
    }
# close the "NetBackupServices" node:
$xmlWriter.WriteEndElement()

#Create Node for DGInfo
$XmlWriter.WriteComment('DiskGroup Information')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'DGInfo')
$CurrentDG = $Null
$Count = 0
IF($DGInfo) {
    ForEach ($Item in $DGInfo) {
        $DG = $Item.Diskgroup
        If ($CurrentDG -ne $DG -and $Count -eq 0) {
            $xmlWriter.WriteStartElement('Diskgroup')
            $XmlWriter.WriteAttributeString('Name', $($Item.Diskgroup))
            }
        ElseIf ($CurrentDG -ne $DG) {
            $xmlWriter.WriteEndElement()
            $xmlWriter.WriteStartElement('Diskgroup')
            $XmlWriter.WriteAttributeString('Name', $($Item.Diskgroup))
            }
        $xmlWriter.WriteStartElement('Property')
        $xmlWriter.WriteAttributeString('Volume', $($Item.Volume))
        $xmlWriter.WriteRaw($($Item.Size))
        $xmlWriter.WriteEndElement()
        $CurrentDG = $DG
        $Count++
        }
    # close the "Diskgroup" node:
    $xmlWriter.WriteEndElement()
    }
# close the "DGInfo" node:
$xmlWriter.WriteEndElement()

#Create Node for Disk Info
$XmlWriter.WriteComment('Disk Info')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'DiskInfo')

ForEach ($Item in $DiskInfo) {
    $xmlWriter.WriteStartElement('Letter')
    $XmlWriter.WriteAttributeString('Name', $($Item.Device))
    $xmlWriter.WriteElementString('Volume', $($Item.Volume))
    $xmlWriter.WriteElementString('Size', $($Item.Size))
    $xmlWriter.WriteElementString('Freespace', $($Item.Freespace))
    $xmlWriter.WriteElementString('BlockSize', $($Item.BlockSize))
    $xmlWriter.WriteEndElement()
    }
# close the "Disk Info" node:
$xmlWriter.WriteEndElement()

#Create Node for NetWork Test
$XmlWriter.WriteComment('Network Test')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'NetTest')

ForEach ($Item in $NetTest) {
    $xmlWriter.WriteStartElement('Connection')
    $XmlWriter.WriteAttributeString('Name', $($Item.Connection))
    $xmlWriter.WriteElementString('State', $($Item.State))
    $xmlWriter.WriteElementString('IPAddress', $($Item.IPAddress))
    $xmlWriter.WriteEndElement()
    }
# close the "NetTest" node:
$xmlWriter.WriteEndElement()

#Create Node for Mobile Test
$XmlWriter.WriteComment('Mobile Test')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'MobileTest')

ForEach ($Item in $MobileTest) {
    $xmlWriter.WriteStartElement('Connection')
    $XmlWriter.WriteAttributeString('Name', $($Item.Connection))
    $xmlWriter.WriteElementString('State', $($Item.State))
    $xmlWriter.WriteElementString('Environment', $($Item.Environment))
    $xmlWriter.WriteEndElement()
    }
# close the "Mobile Test" node:
$xmlWriter.WriteEndElement()

#Create Node for Certificate Test
$XmlWriter.WriteComment('Certificate Test')
$XmlWriter.WriteStartElement('Area')
$XmlWriter.WriteAttributeString('name', 'CertificateTest')

ForEach ($Item in $Certificates) {
    $xmlWriter.WriteStartElement('Certificate')
    $XmlWriter.WriteAttributeString('Name', $($Item.DNSName))
    $xmlWriter.WriteElementString('Issuer', $($Item.Issuer))
    $xmlWriter.WriteElementString('EndDate', $($Item.EndDate))
    $xmlWriter.WriteElementString('Path', $($Item.Path))
    $xmlWriter.WriteEndElement()
    }
# close the "Certificate Test" node:
$xmlWriter.WriteEndElement()

# close the "Server" node:
$xmlWriter.WriteEndElement()

# finalize the document:
$xmlWriter.WriteEndDocument()
#$xmlWriter.Finalize
$xmlWriter.Flush()
$xmlWriter.Close()
#notepad $File
