#Generated Form Function
#[CmdletBinding()]
#param (
#    [Parameter(Mandatory,
#    ValueFromPipeline)]
#    [string]$XMLFile
#)

function RunCompliance () {


    $XMLFile = "compliance.xml"

    $xmlinput = "$($ScriptPath)\XML\$XMLFile"

	[xml] $XMLComp = new-object System.Xml.XmlDocument #Load XML the .Net class
	$XMLComp.load($xmlinput)


    $FailedTests = @()
    $PassedTests = @()
    $Untested = @()



   # ForEach ($HostItem in $Hosts) {

        #$Hosts | ForEach {Write-Host "Hosts: $($_.Host) PD: $($_.PD) Path: $($_.Path) File: $($_.File)" | sort $_.PD} | ft -AutoSize

        $Hostname=hostname
        #$HostName=$HostItem.Host
        #$Global:Path=$HostItem.Path
        #$File=$HostItem.File
        #$Global:PD=$HostItem.PD

#        $XMLCheckFile="$Path\$File"

        $XMLCheckFile="$($ScriptPath)\Result\$((gwmi win32_ComputerSystem).Name).Host-Report.xml"

        Write-Host "XMLCheckFile: $XMLCheckFile"


#        Read-Host "Continue or Not"

        <#
        $richTextBox_Status.Text += "INFO: Starting Compliance Check on $HostName`n"
		$richTextBox_Status.Select()
		$richTextBox_Status.SelectionStart = $richTextBox_Status.Text.Length
		$richTextBox_Status.ScrollToCaret()
		$richTextBox_Status.Refresh()
        #>

    #$xmlCheckFile = "C:\Emis\Host-Report\UAT01\SFBSUAT01DB.Host-Report.xml"
    #$xmlCheckFile = "C:\Emis\Host-Report\TRN01\SFBSTRN01DB.Host-Report.xml"
    #$xmlCheckFile = "C:\Emis\Host-Report\CM001\LSCM001APP01.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\CM001\SFCM001APP01.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\CM001\LSCM001DB.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\CM001\SFCM001DB.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\CM006\LSCM006APP01.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\CM006\LSCM006DB.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\CM006\SFCM006DB.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\GOLD\NYGD004A.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\GOLD\NYGD004AAPP01.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\GOLD\LSGD004A.Host-Report.XML"
    #$xmlCheckFile = "C:\Emis\Host-Report\GOLD\LSGD004AAPP01.Host-Report.XML"
    [xml] $XMLCheck = new-object System.Xml.XmlDocument #Load XML the .Net class
    $XMLCheck.load($xmlCheckFile)


    $Server=$null
    $Domain=$null
    $ReportDate=$Null
    $Environment=$Null

    #Sets basic infomation from the XML file
    $Server = $XMLCheck.server.name
    $Domain = $XMLCheck.server.domain
    $FQDN = $XMLCheck.server.FQDN
    $OU = $XMLCheck.server.OU
    $ReportDate = $XMLCheck.server.date

    #Hacks to cope with different naming conventions
    Switch ($server) {
        #08/12/16 - statements added to deal with environment names in different locations of server name, and mix of CCMH and IOM devices
        #SQL environment variable created to cope with different naming conventions
        {($_.SubString(2,2) -Match "IM" -and $Domain -eq "IOM")} {$Environment = $Server.SubString(2,4); ($SQLEnvironment = $Environment)}
        {($_ -Match "TRN" -and ($Domain -eq "CCMH" -or $Domain -eq "HSCNI" -or $Domain -eq "IOM"))} {($Environment = $Server.SubString($($Server.IndexOf("TRN")),5)); ($SQLEnvironment = $Environment)}
        {($_ -Match "UAT" -and ($Domain -eq "CCMH" -or $Domain -eq "HSCNI" -or $Domain -eq "IOM"))} {($Environment = $Server.SubString($($Server.IndexOf("UAT")),5)); ($SQLEnvironment = $Environment)}
        #{($_.SubString(0,2) -Match "SH|FG")} {$Environment = $Server.SubString(2,7)}
        {($_.SubString(0,2) -Match "SH|FG")} { ($Environment = $Server.SubString(5,4)); ($SQLEnvironment = $Server.SubString(2,7)) }
        {($_.SubString(0,4) -Match "LFCP|LSCP")} { ($Environment = $Server.SubString(5,4)); ($SQLEnvironment = $Server.SubString(2,7)) }
        #06/06 - Updated naming convention again
        #{($_.SubString(0,5) -Match "EN-LS|EN-LF")} {$Environment = $Server.SubString(0,9)}
        #24/01/22 -naminbg convention hacks
        #{($_.SubString(0,5) -Match "EN-LS|EN-LF")} {($Environment = $Server.SubString(5,4)); ($SQLEnvironment = $Server.SubString(0,9)) }
        {($_.SubString(0,5) -Match "EN-LS|EN-LF")} {$Environment = $Server.SubString(5,4); $SQLEnvironment = $Server.Replace("-","_").replace('LS','').replace('LF',''); $CLSEnvironment = $Server.Substring(0,9).Replace('LS','').replace('LF','') }
        #{($_.SubString(0,5) -Match "ENLS|ENLF")} {($Environment = $Server.SubString(4,6)); ($SQLEnvironment = $Server.SubString(0,9)) }
        {($_.SubString(0,5) -Match "ENLS|ENLF")} {$Environment = $Server.SubString(4,6); $SQLEnvironment = $Server.Replace("-","_").replace('LS','').replace('LF',''); $CLSEnvironment = $Server.Substring(0,10).Replace('LS','').replace('LF','')}
        #{($a.SubString(0,4) -Match "ENLS|ENLF")} {$Environmenta = $a.SubString(4,6); $SQLEnvironmenta = $a.Replace("-","_").replace('LS','').replace('LF',''); $CLSEnvironmenta = $a.Substring(0,10).Replace('LS','').replace('LF','')}
        #CM 'firecracker' builds added 14/07/2022
        {($_.SubString(0,4) -Match "CMLS|CMLF")} {$Environment = $Server.SubString(4,6).replace("GP","CM"); $SQLEnvironment = $Server.Replace("-","_").replace('LS','').replace('LF',''); $CLSEnvironment = $Server.Substring(0,10).Replace('LS','').replace('LF','')}
        {($Domain -eq "EmisGha")} {$Environment = ($HostItem.PD).Replace("GIB","")} #Hack to deal with folder name in GIB
        {($_.SubString(0,6) -Match "ENEUW2")} {$Environment = $Server.SubString(6,4); $SQLEnvironment = $Server.Replace("-","_").Replace('DBS01','DB').replace('DBS02','DB'); $CLSEnvironment = $Server.Substring(0,11).Replace('DBS01','DB').replace('DBS02','DB')}
        #MH 10/01/23 - Next 3 lines determine the environment, these are AWS specific
        {($_ -Match "ENEUW2DEV")} {$Environment = $Server.SubString(6,3); $SQLEnvironment = $Server.Replace("-","_").Replace('DBS01','DB').replace('DBS02','DB');} #$CLSEnvironment = $Server.Substring(0,11).Replace('DBS01','DB').replace('DBS02','DB')}
        {($_ -Match "ENEUW2STG")} {$Environment = $Server.SubString(6,3); $SQLEnvironment = $Server.replace('RS-01','RS').Replace("-","_").Replace('DBS01','DB').replace('DBS02','DB');} #$CLSEnvironment = $Server.Substring(0,11).Replace('DBS01','DB').replace('DBS02','DB')}
        {($_ -Match "ENEUW2GP")} {$Environment = $Server.SubString(6,4); $SQLEnvironment = $Server.replace('RS-01','RS').Replace("-","_").Replace('DBS01','DB').replace('DBS02','DB');} #$CLSEnvironment = $Server.Substring(0,11).Replace('DBS01','DB').replace('DBS02','DB')}
        default {$Environment = $Server.SubString(2,5); ($SQLEnvironment = $Environment)}
        }

    #$Environment = $Server.SubString(2,5) #CCMH training systems have a differenent naming convention
    #OS
    Switch (($XMLCheck.server.area | ? {$_.name -eq "osinfo"}).property | ? {$_.name -eq "operating system"}) {
        {$_.'#text' -match "2008"} {$osVer="2008"}
        {$_.'#text' -match "2012"} {$osVer="2012"}
        {$_.'#text' -match "2016"} {$osVer="2016"}
        {$_.'#text' -match "2019"} {$osVer="2019"}
        default {$osver = "unknown"}
        }

    #Load Areas to verify from server XML file
    $osSource=$Null
    $osSource = ($XMLCheck.server.area | ? {$_.name -eq "osinfo"}).property

    $NetworkInfoSource=@()
    $NetworkInfoSource=($xmlCheck.server.area | ? {$_.name -eq "NetworkInfo"}).Nic | ? {$_.Niclabel}# -match "Ethernet|Ethernet 2|Ethernet 3"} #"Public|Private|Backup|Witness"}

    $DNSSource=$Null
    $DnsSource = ($XMLCheck.server.area | ? {$_.name -eq "dnsinfo"}).dns

    $RouteInfoSource=$Null
    $RouteInfoSource=($xmlCheck.server.area | ? {$_.name -eq "RouteInfo"}).Route | ? {$_.Destination}

    $HostFileInfoSource=$Null
    $HostFileInfoSource=($xmlCheck.server.area | ? {$_.name -eq "HostFileInfo"}).HostFile | ? {$_.Name}

    $DataDogSource=$Null
    $DataDogSource=($xmlCheck.server.area | ? {$_.name -eq "DataDogServices"}).Service | ? {$_.Name}

    $AntiVirusSource=$Null
    $AntiVirusSource=($xmlCheck.server.area | ? {$_.name -eq "AntiVirus"}).property | ? {$_.Name}

    $MonitoringServicesSource=$Null
    $MonitoringServicesSource=($xmlCheck.server.area | ? {$_.name -eq "MonitoringServices"}).Service | ? {$_.Name}

    $ProgramInfoSource=$Null
    $ProgramInfoSource=($xmlCheck.server.area | ? {$_.name -eq "ProgramInfo"}).property | ? {$_.Name}

    $SQLInfoSource=$Null
    $SQLInfoSource=($xmlCheck.server.area | ? {$_.name -eq "SQLInfo"}).SQLInstanceInfo | ? {$_.Instance}

    $SQLAccessSource=$Null
    $SQLAccessSource=($xmlCheck.server.area | ? {$_.name -eq "SQLAccess"}).SQLAccessInfo | ? {$_.Instance}

    $SQLLoginsSource=$Null
    $SQLLoginsSource=($xmlCheck.server.area | ? {$_.name -eq "SQLLogins"}).SQLLoginInfo | ? {$_.Instance}

    $SQLServiceSPNsSource=$Null
    $SQLServiceSPNsSource=($xmlCheck.server.area | ? {$_.name -eq "SQLServiceSPNs"}).SQLServiceSPN | ? {$_.SPN}

    $DBChecksSource=$Null
    $DBChecksSource=($xmlCheck.server.area | ? {$_.name -eq "DBChecks"}).property | ? {$_.Name}

    $AppServicesSource=$Null
    $AppServicesSource=($xmlCheck.server.area | ? {$_.name -eq "AppServices"}).Service | ? {$_.Name}

    $AppFilesSource=$Null
    $AppFilesSource=($xmlCheck.server.area | ? {$_.name -eq "AppFiles"}).Property | ? {$_.Name}

    $ClusterInfoSource=$Null
    $ClusterInfoSource=($xmlCheck.server.area | ? {$_.name -eq "ClusterInfo"}).Property | ? {$_.Name}

    $NetBackupServicesSource=$Null
    $NetBackupServicesSource=($xmlCheck.server.area | ? {$_.name -eq "NetBackupServices"}).Service | ? {$_.Name}

    $DGInfoSource=$Null
    $DGInfoSource=($xmlCheck.server.area | ? {$_.name -eq "DGInfo"}).DiskGroup | ? {$_.Name}

    $DiskInfoSource=$Null
    $DiskInfoSource=($xmlCheck.server.area | ? {$_.name -eq "Diskinfo"}).Letter | ? {$_.Name}

    $NetTestSource=$Null
    $NetTestSource=($xmlCheck.server.area | ? {$_.name -eq "NetTest"}).Connection | ? {$_.Name}

    $MobileTestSource=$Null
    $MobileTestSource=($xmlCheck.server.area | ? {$_.name -eq "MobileTest"}).Connection | ? {$_.Name}

    $CertificateTestSource=$Null
    $CertificateTestSource=($xmlCheck.server.area | ? {$_.name -eq "CertificateTest"}).Certificate | ? {$_.Name}

    #Set the Server type Readable secondary type added (05/04/16)

    Write-Host "$($SQLInfoSource.instance)"

    $ServerType="Unknown"
    IF ($SQLInfoSource.instance) {$ServerType="DataBase"}

    #IF ($AppServicesSource.name -eq "Emis.Services.WindowsService") {$ServerType="App"}
    IF ($AppServicesSource.name -eq "Emis.Connect.Core.Host") {$ServerType="App"}
    IF ($Hostname -match "App") {$ServerType="App"}
    IF ($Hostname -match "App01|App02|App03|App07|App08|App09" -and $AppServicesSource.name -eq "Emis.Services.WindowsService" -and $AppServicesSource.name -eq "Emis.Scheduler.WindowsService") {$ServerType="EW-Private"}
    IF ($Hostname -match "App04|App05|App10|App11" -and $AppServicesSource.name -eq "Emis.Services.WindowsService") {$ServerType="EW-Public"}
    IF ($Hostname -match "App06|App12" -and $AppServicesSource.name -eq "Emis.ExternalMessaging.WindowsCoreService") {$ServerType="EMAS"}

    IF ($SQLInfoSource.instance -And $AppServicesSource.name -eq "Emis.Services.WindowsService") {$ServerType="StandardCombi"}
    IF ($SQLInfoSource.instance -And $AppServicesSource.name -eq "Emis.Connect.Core.Host") {$ServerType="StandardCombi"}

    IF ($SQLInfoSource.instance -And $AppServicesSource.name -eq "Emis.Services.WindowsService" -And $Environment -match "UAT|TRN") {$ServerType="OneBoxCombi"}
    IF ($SQLInfoSource.instance -And $AppServicesSource.name -eq "Emis.Connect.Core.Host" -And $Environment -match "UAT|TRN") {$ServerType="OneBoxCombi"}

    IF ($SQLInfoSource.instance -And $ClusterInfoSource.name -eq "Cluster Name") {$ServerType="ClusterDB"}
    If ($Server.length -ge 11) {
        Switch ( $OsVer )  {
            # "2012" { If ($SQLInfoSource.instance -And $ClusterInfoSource.name -eq "Cluster Name" -And $Server.SubString(9,3) -eq "RS-") {$ServerType="ClusterRSDB"} }
            "2019" { If ($SQLInfoSource.instance -And $ClusterInfoSource.name -eq "Cluster Name" -And $Server.SubString(9,3) -eq "RS-") {$ServerType="ClusterRSDB"} } #Copes with dev/stg AWS naming convention
            "2019" { If ($SQLInfoSource.instance -And $ClusterInfoSource.name -eq "Cluster Name" -And $Server.SubString(10,3) -eq "RS-") {$ServerType="ClusterRSDB"} } #Copes with prd AWS naming convention
            }
        }

    IF ($SQLInfoSource.instance -And $ClusterInfoSource.name -eq "Cluster Name" -And $AppServicesSource.name -eq "Emis.Services.WindowsService") {$ServerType="ClusterCombi"}
    IF ($SQLInfoSource.instance -And $ClusterInfoSource.name -eq "Cluster Name" -And $AppServicesSource.name -eq "Emis.Connect.Core.Host") {$ServerType="ClusterCombi"}


    <#
    #############Test 19/01/2022

    If ( $Server -Match "app" ) { $ServerType = "App" }

    #############End Test
    #>

    #Sets the servers location based on the first two characters of the server name
    #06/06/16 - another naming convention
    Switch ($Server) {
        #{ $_.SubString(0,2) -eq "LS" -OR $_.SubString(0,2) -eq "B-" -OR $_.SubString(0,2) -eq "SH" -OR $_.SubString(3,2) -eq "LS" -OR $_.SubString(0,4) -eq "ENLS" -OR $_.SubString(0,4) -eq "CMLS"} {$Site="Failover"}
        {$_.name -match "DBS02"} {$Site="Failover"}
        default {$Site="Production"}
        }

    Write-Host "Site : $Site"

    #Load Areas to verify from Compliance XML File
    $osComp=@()
    $osComp = ($XMLComp.compliance.Area | ? {$_.name -eq "osinfo"}).property | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}
    #$osComp = ($XMLComp.compliance.Area | ? {$_.name -eq "osinfo"}).property | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $NetworkInfoComp=@()
    $NetworkInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "Networkinfo"}).nic | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}
    #$NetworkInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "Networkinfo"}).nic | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $RouteInfoComp=@()
    $RouteInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "Routeinfo"}).route | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All")}}
    #$RouteInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "Routeinfo"}).route | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $HostFileInfoComp=$Null
    $HostFileInfoComp = ($XMLComp.compliance.Area | ? {$_.name -eq "HostFileInfo"}).Hostfile | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All") -and ($_.Site -match $Site -or $_.Site -eq "All")}}

    $DataDogServicesInfoComp=$Null
    $DataDogServicesInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "DataDogServices"}).Service | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}

    $AntiVirusComp=$Null
    $AntiVirusComp=($XMLComp.compliance.Area | ? {$_.name -eq "AntiVirus"}).property | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}
    #$AntiVirusComp=($XMLComp.compliance.Area | ? {$_.name -eq "AntiVirus"}).property | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    #$TelegrafSerivcesComp=$Null
    #$TelegrafSerivcesComp=($XMLComp.compliance.Area | ? {$_.name -eq "AntiVirus"}).property | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}
    $MonitoringServicesInfoComp=$Null
    $MonitoringServicesInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "MonitoringServices"}).Service | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}

    $ProgramInfoComp=$Null
    $ProgramInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "ProgramInfo"}).property | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $SQLInfoComp=$Null
    $SQLInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "SQLInfo"}).SQLInstanceInfo | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}
    #$SQLInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "SQLInfo"}).SQLInstanceInfo | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $SQLAccessComp=$Null
    $SQLAccessComp=($XMLComp.compliance.Area | ? {$_.name -eq "SQLAccess"}).SQLAccessInfo | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}
    #$SQLAccessInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "SQLAccess"}).SQLAccessInfo | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $SQLLoginsInfoComp=$Null
    $SQLLoginsInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "SQLLogins"}).SQLLoginInfo | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}

    $SQLServiceSPNsInfoComp=$Null
    $SQLServiceSPNsInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "SQLServiceSPNs"}).SQLServiceSPN | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}

    $DBChecksInfoComp=$Null
    $DBChecksInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "DBChecks"}).property | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}

    $AppServicesInfoComp=$Null
    $AppServicesInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "AppServices"}).Service | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}
    #$AppServicesInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "AppServices"}).Service | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $AppFilesInfoComp=$Null
    $AppFilesInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "AppFiles"}).Property | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}

    $ClusterInfoComp=$Null
    $ClusterInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "ClusterInfo"}).Property | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All") -and ($server.substring($server.length -10) -match $_.ServerID -OR $_.ServerID -eq "All") }}

    $NetBackupServicesInfoComp=$Null
    $NetBackupServicesInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "NetBackupServices"}).Service | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $DiskInfoComp=@()
    $DiskInfoComp=($XMLComp.COMPLIANCE.area | ? {$_.name -eq "DiskInfo"}).letter | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All") -and ($server.substring($server.length -10) -match $_.ServerID -OR $_.ServerID -eq "All") }}

    $DGInfoComp=@()
    $DGInfoComp=($XMLComp.COMPLIANCE.area | ? {$_.name -eq "DGInfo"}).diskgroup | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $NetTestInfoComp=$Null
    $NetTestInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "NetTest"}).Connection | % {$_ | ? {($_.servertype -match $Servertype -or $_.ServerType -eq "All") -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}
    #$NetTestInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "NetTest"}).Connection | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $MobileTestInfoComp=$Null
    $MobileTestInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "MobileTest"}).Connection | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer}}

    $CertificateTestInfoComp=$Null
    $CertificateTestInfoComp=($XMLComp.compliance.Area | ? {$_.name -eq "CertificateTest"}).Certificate | % {$_ | ? {$_.servertype -match $Servertype -or $_.ServerType -eq "All" -and $_.os -match $osVer -and ($_.Domain -match $Domain -or $_.Domain -eq "All") -and ($_.Environment -match $Environment -or $_.Environment -eq "All")}}

    Write-Host "Server : $Server"
    Write-Host "Domain : $Domain"
    Write-Host "FQDN : $FQDN"
    Write-Host "Organizational Unit : $OU"
    Write-Host "ServerType : $ServerType"
    Write-Host "Operating System : $OsVer"
    Write-Host "Environment : $Environment"
    Write-Host "SQL Environment : $SQLEnvironment"
    Write-Host "ServerType : $ServerType"
    Write-Host "Cluster Environment : $CLSEnvironment"

###########################################

    #DNS Testing
    $DNSTest = @()
    Write-Host "DNS Testing"
    #Returns DNS Servers from Server XML
    #$DnsSource = ($XMLCheck.server.area | ? {$_.name -eq "dnsinfo"}).dns

    $PriDNS=@()
    $SecDNS=@()
    $TerDNS=@()
    $QuaDNS=@()

    #Sets the DNS order from the check file based on the servers location
    Switch ($Site) {
        {$_ -eq "Failover"} {$PriDNS = (($XMLComp.compliance.area | ? {$_.name -eq "dnsinfo"}).domain | ? {$_.name -match $Domain -and ($_.servertype -match $Servertype -or $_.ServerType -eq "All")}).Tertiary
            $SecDNS = (($XMLComp.compliance.area | ? {$_.name -eq "dnsinfo"}).domain | ? {$_.name -match $Domain -and ($_.servertype -match $Servertype -or $_.ServerType -eq "All")}).Quaternary
            $TerDNS = (($XMLComp.compliance.area | ? {$_.name -eq "dnsinfo"}).domain | ? {$_.name -match $Domain -and ($_.servertype -match $Servertype -or $_.ServerType -eq "All")}).Primary
            $QuaDNS = (($XMLComp.compliance.area | ? {$_.name -eq "dnsinfo"}).domain | ? {$_.name -match $Domain -and ($_.servertype -match $Servertype -or $_.ServerType -eq "All")}).Secondary}
        {$_ -eq "Production"} {$PriDNS = (($XMLComp.compliance.area | ? {$_.name -eq "dnsinfo"}).domain | ? {$_.name -match $Domain -and ($_.servertype -match $Servertype -or $_.ServerType -eq "All")}).primary
            $SecDNS = (($XMLComp.compliance.area | ? {$_.name -eq "dnsinfo"}).domain | ? {$_.name -match $Domain -and ($_.servertype -match $Servertype -or $_.ServerType -eq "All")}).Secondary
            $TerDNS = (($XMLComp.compliance.area | ? {$_.name -eq "dnsinfo"}).domain | ? {$_.name -match $Domain -and ($_.servertype -match $Servertype -or $_.ServerType -eq "All")}).Tertiary
            $QuaDNS = (($XMLComp.compliance.area | ? {$_.name -eq "dnsinfo"}).domain | ? {$_.name -match $Domain -and ($_.servertype -match $Servertype -or $_.ServerType -eq "All")}).Quaternary}
        }

    #DNS Search order test
    ForEach ($Item in $DnsSource) {
        $DNSHealth = $Null

        If ($Item.order -eq "Primary") {
            Switch ($($Item.DNSServer)) {
                {$_ -eq $PriDNS.'#text' -and $Item.NicLabel -match $PriDNS.NIC} {
                    #Write-Host "$($Item.Order) Dns Server $($Item.DNSServer) correct for Domain $($Domain)"
                    $DNSHealth = "OK"
                    $Status="Pass"
                    }
                {$_ -eq $PriDNS.'#text' -and $Item.NicLabel -notmatch $PriDNS.NIC} {
                    #Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using incorrect Nic $($Item.NicLabel). Expected NIC $(((($XMLComp.compliance.area | ? {$_.name -match "dnsinfo"}).domain | ? {$_.name -match $Domain}).childnodes | ? {$_.'#text' -eq $($Item.DNSServer)}).Nic)"
                    $DNSHealth = "Wrong NIC"
                    $Status="Fail"
                    }
                {$_ -ne $PriDNS.'#text' -and $Item.NicLabel -notmatch $PriDNS.NIC} {
                    #Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using incorrect Nic $($Item.NicLabel) and DNS Server. Expected DNS Server $($PriDNS.'#text')"
                    $DNSHealth = "Wrong NIC and DNS Server"
                    $Status="Fail"
                    }
                Default {
                    #Write-Warning "$($Server) $($Item.Order) Dns Server $($Item.DNSServer) incorrect was expecting $($PriDNS.'#text') for Domain $($Domain)"
                    $DNSHealth = "Incorrect DNS Server Set"
                    $Status="Fail"
                    }
                }
            }
        ElseIf ($item.order -eq "Secondary") {
            Switch ($($Item.DNSServer)) {
                {$_ -eq $SecDNS.'#text' -and $Item.NicLabel -match $SecDNS.NIC} {
                    #Write-Host "$($Item.Order) Dns Server $($Item.DNSServer) correct for Domain $($Domain)"
                    $DNSHealth = "OK"
                    $Status="Pass"
                    }
                {$_ -eq $SecDNS.'#text' -and $Item.NicLabel -notmatch $SecDNS.NIC} {
                    #Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using incorrect Nic $($Item.NicLabel). Expected NIC $(((($XMLComp.compliance.area | ? {$_.name -match "dnsinfo"}).domain | ? {$_.name -match $Domain}).childnodes | ? {$_.'#text' -eq $($Item.DNSServer)}).Nic)"
                    $DNSHealth = "Wrong NIC"
                    $Status="Fail"
                    }
                {$_ -ne $SecDNS.'#text' -and $Item.NicLabel -notmatch $SecDNS.NIC} {
                    Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using incorrect Nic $($Item.NicLabel) and DNS Server.  Expected DNS Server $($SecDNS.'#text')"
                    $DNSHealth = "Wrong NIC and DNS Server"
                    $Status="Fail"
                    }
                Default {
                    Write-Warning "$($Server) $($Item.Order) Dns Server $($Item.DNSServer) incorrect was expecting $($SecDNS.'#text') for Domain $($Domain)"
                    $DNSHealth = "Incorrect DNS Server Set"
                    $Status="Fail"
                    }
                }
            }
        ElseIf ($item.order -eq "Tertiary") {
            Switch ($($Item.DNSServer)) {
                {$_ -eq $TerDNS.'#text' -and $Item.NicLabel -match $TerDNS.NIC} {
                    #Write-Host "$($Item.Order) Dns Server $($Item.DNSServer) correct for Domain $($Domain)"
                    ;$DNSHealth = "OK"
                    ;$Status="Pass"
                    }
                {$_ -eq $TerDNS.'#text' -and $Item.NicLabel -notmatch $TerDNS.NIC} {
                    #Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using incorrect Nic $($Item.NicLabel). Expected NIC $(((($XMLComp.compliance.area | ? {$_.name -match "dnsinfo"}).domain | ? {$_.name -match $Domain}).childnodes | ? {$_.'#text' -eq $($Item.DNSServer)}).Nic)"
                    $DNSHealth = "Wrong NIC"
                    $Status="Fail"
                    }
                {$_ -ne $TerDNS.'#text' -and $Item.NicLabel -notmatch $TerDNS.NIC} {
                    #Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using incorrect Nic $($Item.NicLabel) and DNS Server.  Expected DNS Server $($SecDNS.'#text')"
                    $DNSHealth = "Wrong NIC and DNS Server"
                    $Status="Fail"
                    }
                Default {
                    #Write-Warning "$($Server) $($Item.Order) Dns Server $($Item.DNSServer) incorrect was expecting $($SecDNS.'#text') for Domain $($Domain)"
                    $DNSHealth = "Incorrect DNS Server Set"
                    $Status="Fail"
                    }
                }
            }
        ElseIf ($item.order -eq "Quaternary") {
            Switch ($($Item.DNSServer)) {
                {$_ -eq $QuaDNS.'#text' -and $Item.NicLabel -match $QuaDNS.NIC} {
                    #Write-Host "$($Item.Order) Dns Server $($Item.DNSServer) correct for Domain $($Domain)"
                    ;$DNSHealth = "OK"
                    ;$Status="Pass"
                    }
                {$_ -eq $QuaDNS.'#text' -and $Item.NicLabel -notmatch $QuaDNS.NIC} {
                    #Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using incorrect Nic $($Item.NicLabel). Expected NIC $(((($XMLComp.compliance.area | ? {$_.name -match "dnsinfo"}).domain | ? {$_.name -match $Domain}).childnodes | ? {$_.'#text' -eq $($Item.DNSServer)}).Nic)"
                    $DNSHealth = "Wrong NIC"
                    $Status="Fail"
                    }
                {$_ -ne $QuaDNS.'#text' -and $Item.NicLabel -notmatch $QuaDNS.NIC} {
                    #Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using incorrect Nic $($Item.NicLabel) and DNS Server.  Expected DNS Server $($SecDNS.'#text')"
                    $DNSHealth = "Wrong NIC and DNS Server"
                    $Status="Fail"
                    }
                Default {
                    #Write-Warning "$($Server) $($Item.Order) Dns Server $($Item.DNSServer) incorrect was expecting $($SecDNS.'#text') for Domain $($Domain)"
                    $DNSHealth = "Incorrect DNS Server Set"
                    $Status="Fail"
                    }
                }
            }
        Else {
            #Write-Warning "$($Item.Order) Dns Server $($Item.DNSServer) using Nic $($Item.NicLabel) unexpected"
            $DNSHealth = "Unkown Configuration"
            $Status="Fail"
            }

        IF ($DNSHealth -eq $True) {
            $DNSTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "DNS"
                Property = "Order: $($Item.order)<br/>Nic: $($Item.NicLabel)<br/>Server: $($Item.DNSServer)"
	            Value = $DNSHealth
                Status = $Status
			    }
            }
        Else {
            $DNSTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "DNS"
                Property = "Order: $($Item.order)<br/>Nic: $($Item.NicLabel)<br/>Server: $($Item.DNSServer)"
	            Value = $DNSHealth
                Status = $Status
			    }
            }
        }
    #End DNS Tests

###################################

    #OS Info
    Write-Host "OS Tests"
    $osTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    $PreviousEnvironment = $Environment

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    Switch ($Environment.Length) {
        {$_ -eq 7} {$Environment = $Environment.SubString(3,4)}
        {$_ -eq 9} {$Environment = $Environment.SubString(5,4)}
        {$_ -eq 8 -and $Environment -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        default {$Environment = $Environment}
        }
    #23/01/22 (MH) - Hack for new environment name used in 2019 os
    If ( $os = "2019" ) { $Environment = $Environment.Replace("-1","") }

    Write-Host "Temp Environment: $Environment"

    ForEach ($Item in $osComp) {
        $Found=$False
        #Matched Items Expected and Correct

        ##### Test 23/01/2022
        #Write-Host "$($item.name): $($item.'#text')"
        #Write-Host ""

        $Passed+=$osSource | ? {$_.name -match [Regex]::Escape($item.name)} | ? {$_.'#text' -match [Regex]::Escape($Item.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',"$Domain") -and $Item.State -match "Expected"}
        IF ($osSource | ? {$_.name -match [Regex]::Escape($item.name)} | ? {$_.'#text' -match [Regex]::Escape($Item.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',"$Domain") -and $Item.State -match "Expected"}) {
            #Write-Host "Passed: $($Passed[-1].Name) / $($Passed[-1].'#text')"
            $Found=$True
            }
        #Matched Items which shoudn't be present and indicate a failure
        $Failed+=$osSource | ? {$_.name -match [Regex]::Escape($item.name)} | ? {$_.'#text' -match [Regex]::Escape($Item.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',"$Domain") -and $Item.State -match "Fail"}
        IF ($osSource | ? {$_.name -match [Regex]::Escape($item.name)} | ? {$_.'#text' -match [Regex]::Escape($Item.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',"$Domain") -and $Item.State -match "Fail"}) {
            $Found=$True
            }
        #Matched Area where a certain string is expected anything returned here is a failure
        #$WrongValue+=$osSource | ? {$_.name -match $item.name} | ? {$_.'#text' -notmatch [Regex]::Escape($Item.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) -and $Item.State -match "All"}
        #Updated 23/01/2022 incorrect logic... muppet
        $WrongValue+=$osSource | ? {$_.name -match [Regex]::Escape($item.name)} | ? {$_.'#text' -notmatch [Regex]::Escape($Item.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',"$Domain") -and $Item.State -match "All"}
        IF ($osSource | ? {$_.name -match [Regex]::Escape($item.name)} | ? {$_.'#text' -notmatch [Regex]::Escape($Item.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',"$Domain") -and $Item.State -match "All"}) {
            $Found=$True
            }
        #MissingValues
        If (!($Found) -and $item.State -eq "Expected") {
            $MissingValue+=$Item | select name,'#text'.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',"$Domain")
            #Write-Host "Missing: $($Item | select name,'#text'.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))"
            }
        }

    $Passed | % { $osTest += New-Object -TypeName PSObject  -Property @{
            Server = $Server
            Test = "OS"
		    Property = $($_.name)
		    Value = $($_.'#text')
	        Status = "Pass"
		    }
        }
    $Failed | % { $osTest += New-Object -TypeName PSObject  -Property @{
            Server = $Server
            Test = "OS"
		    Property = $($_.name)
		    Value = $($_.'#text')
	        Status = "Failed"
		    }
        }
    $WrongValue | % { $osTest += New-Object -TypeName PSObject  -Property @{
            Server = $Server
            Test = "OS"
		    Property = $($_.name)
		    Value = $($_.'#text')
	        Status = "Fail Incorrect"
		    }
        }
    $MissingValue | % { $osTest += New-Object -TypeName PSObject  -Property @{
            Server = $Server
            Test = "OS"
		    Property = $($_.name)
		    Value = $($_.'#text'.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX', $Domain))
	        Status = "Fail Missing"
		    }
        }

    #Write-Host "...."
    #List the untested Elements
    ForEach ($Object in $OsSource ) {
        IF (!($ostest.property -Contains $object.Name -and $ostest.value -contains $object.'#text')) {
            $osTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "OS"
			    Property = $($Object.name)
			    Value = ($($Object.'#text'))
	            Status = "Untested"
			    }
            }
        }
    If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}

    Write-Host "Post OS Environment: $Environment"


    #End OS Compare

###################################

    #DiskInfo Info

    Write-Host "DiskInfo Tests"
    $DiskInfoTest=@()
    #$Passed=@()
    #$Failed=@()
    #$WrongValue=@()
    #$MissingValue=@()

    ForEach ($Item in $DiskInfoComp) {
        $Passed=@()
        $Failed=@()
        $WrongValue=@()
        $MissingValue=@()
        $FailStatus = @()
        $Found=$False
        #Write-Host "DiskInfo Environment: $Environment"
        #Matched Items Expected and Correct
        ##If ($DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume}) {
        If ($DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume -And $_.BlockSize -eq $Item.BlockSize}) {
            $Found = $True
            #$Passed+=$DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume}
            ##$Passed+=$DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume}
            ##$Passed+=$DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume -And $_.BlockSize -eq $Item.BlockSize}
            $Passed = $DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume -And $_.BlockSize -eq $Item.BlockSize}
            $Passed | % {$DiskInfoTest += New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Test = "Disk Info"
		            Property = $($_.name)
		            Value = "Volume: $($_.volume)<br/>BlockSize: $($_.BlockSize)"
		            Volume = $($_.volume)
	                Status = "Pass"
		            }
                }
            }
        #Matched Area where a certain string is expected anything returned here is a failure
        ##If ($DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -ne $Item.volume}) {
        If ($DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -ne $Item.volume -Or $_.BlockSize -ne $Item.BlockSize}) {
            $Found=$True
            ##$WrongValue+=$DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -ne $Item.volume}
            ##$WrongValue+=$DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -ne $Item.volume -Or $_.BlockSize -ne $Item.BlockSize}
            $WrongValue = $DiskInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -ne $Item.volume -Or $_.BlockSize -ne $Item.BlockSize}
            Switch ($WrongValue) {
                { $_.Volume -ne $Item.Volume } { $FailStatus="VolumeName:$($_.Volume)<br>" }
                { $_.BlockSize -ne $Item.BlockSize } { $FailStatus=$FailStatus+"BlockSize:$($_.BlockSize)<br>" }
                }
            $WrongValue | % {$DiskInfoTest += New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Test = "Disk Info"
		            Property = $($_.name)
		            Value = "Volume: $($_.volume)<br/>BlockSize: $($_.BlockSize)"
		            Volume = $($_.volume)
	                Status = "Fail:<br/>$FailStatus"
		            }
                }
            }
        #MissingValues
        If (!($Found)) {
            ##$MissingValue+=$Item | select name,volume,blocksize
            $MissingValue = $Item | select name,volume,blocksize
            $MissingValue | % {$DiskInfoTest += New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Test = "Disk Info"
		            Property = $($_.name)
		            Value = "Volume: $($_.volume)<br/>BlockSize: $($_.BlockSize)"
		            Volume = $($_.volume)
	                Status = "Fail Missing"
		            }
                }
            }
        }
    #List the untested Elements
    ForEach ($Object in $DiskInfoSource) {
        #Write-Host "$($Object.name) : $($Object.volume)"
        If (!($DiskInfoTest.Property -Contains $object.Name -and $DiskInfoTest.Volume -contains $object.volume)) {
            ##Write-Host "Not tested.... $($Object.name) : $($Object.volume)"
            $DiskInfoTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "Disk Info"
			    Property = $($Object.Name)
			    Value = "Volume: $($Object.volume)<br/>BlockSize: $($Object.BlockSize)"
	            Status = "Fail Unexpected"
			    }
            }
        }
    #End DiskInfo Compare

###################################

    #DGInfo Test

    #Return to this later
    <#

    Write-Host "DGInfo Tests"
    $DGInfoTest=@()
    $Passed=@()
    #$Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    ForEach ($Item in $DGInfoComp) {
        $Found=$False
        Write-Host "Items -- $($Item.name.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)) : $($Item.property.volume)"
        #Matched Items Expected and Correct
        $Passed+=$DGInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume}
        IF ($DGInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume}) {
            $Found=$True
            $DGInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -Eq $Item.volume} | % {Write-Host "Item Passed -- $($_.name) : $($_.volume)"}
            }
        #Matched Area where a certain string is expected anything returned here is a failure
        $WrongValue+=$DGInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -ne $Item.volume}
        IF ($DGInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -ne $Item.volume}) {
            $Found=$True
            Write-Warning "Item Wrong setting -- $($Item.name) : $($Item.volume)"
            $DGInfoSource | ? {$_.name -match $item.name} | ? {$_.volume -ne $Item.volume} | % {Write-Warning "Item Wrong setting -- $($_.name) : $($_.volume)"}
            }
        #MissingValues
        If (!($Found)) {
            $MissingValue+=$Item | select name,volume
            #$MissingValue=$MissingValue | % {$_.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)}
            Write-Warning "Item Not Found!! -- $($Item.name) : $($Item.volume)"
            }
        }

    $Passed | % {$DGInfoTest += New-Object -TypeName PSObject -Property @{
            Test = "Disk Info"
		    Property = $($_.name)
		    Value = $($_.volume)
	        Status = "Pass"
		    }
        }
    $WrongValue | % {$DGInfoTest += New-Object -TypeName PSObject -Property @{
            Test = "Disk Info"
		    Property = $($_.name)
		    Value = $($_.volume)
	        Status = "Fail Incorrect"
		    }
        }
    $MissingValue | % {$DGInfoTest += New-Object -TypeName PSObject -Property @{
            Test = "Disk Info"
		    Property = $($_.name)
		    Value = $($_.volume)
	        Status = "Fail Missing"
		    }
        }
    Write-Host "...."
    #List the untested Elements

    ForEach ($Object in $DGInfoSource) {
        Write-Host "$($Object.name) : $($Object.volume)"
        IF (!($DGInfoTest.Property -Contains $object.Name -and $DGInfoTest.value -contains $object.volume)) {
            #Write-Host "Not tested.... $($Object.name) : $($Object.volume)"
            $DGInfoTest += New-Object -TypeName PSObject  -Property @{
                Test = "Disk Info"
			    Property = $($Object.Name)
			    Value = ($($Object.volume))
	            Status = "Untested"
			    }
            }
        } #>
    #End DG Compare


###################################


    #NetworkInfo Tests

    Write-Host "NetworkInfo Tests"
    $NetworkInfoTest = @()
    $Passed = @()
    #$Failed=@()
    $WrongMaskValue = @()
    $WrongGateWay = @()
    $MissingValue = @()
    $WrongStatus = @()

    ForEach ($Item in $NetworkInfoComp) {
        $Found=$False
        [ref]$a=$null #required to validate ip address

        #$Passed+=$NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$Nic=$_;$Nic.Mask -Eq $Item.Mask -and ( ([ipaddress]::tryparse($($Nic.Gateway),$a) | ? {$Nic.niclabel -match $item.NicLabel}  ) -eq $Item.Gateway)   } #-or (!([ipaddress]::tryparse($($_.Gateway),$a) -eq $Item.Gateway)) ) }
        $Nic=$null
        $Passed += $NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$Nic=$_;$Nic.Mask -Eq $Item.Mask -and ( ( $Nic.Gateway -eq "None Configured"  -and  $Item.GateWay -eq "False"  ) -or ( $Nic.Gateway -ne "None Configured"  -and  $Item.GateWay -eq "True"  ) ) -And $Nic.Status -eq $Item.Status  }

        IF ($NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$Nic=$_;$Nic.Mask -Eq $Item.Mask -and ( ( $Nic.Gateway -eq "None Configured"  -and  $Item.GateWay -eq "False"  ) -or ( $Nic.Gateway -ne "None Configured"  -and  $Item.GateWay -eq "True"  ) ) -And $Nic.Status -eq $Item.Status   }) {
            $Found = $True
            }

        #Matched NIC Labels but Mask different than expected
        $WrongMaskValue+=$NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$_.Mask -ne $Item.Mask}
        IF ($NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$_.Mask -ne $Item.Mask}) {
            $Found = $True
            }

        #Matched NIC Labels and Mask but Default gateway either set or not set when it shouldn't or should be
        $Nic=$null
        $WrongGateWay += $NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$Nic=$_;$Nic.Mask -Eq $Item.Mask -and ( ( $Nic.Gateway -ne "None Configured"  -and  $Item.GateWay -eq "False"  ) -or ( $Nic.Gateway -eq "None Configured"  -and  $Item.GateWay -eq "True"  ) )   }
        IF ($NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$Nic=$_;$Nic.Mask -Eq $Item.Mask -and ( ( $Nic.Gateway -ne "None Configured"  -and  $Item.GateWay -eq "False"  ) -or ( $Nic.Gateway -eq "None Configured"  -and  $Item.GateWay -eq "True"  ) )    }) {
            $Found = $True
            }

        #Matched NIC Labels but Mask different than expected
        $WrongStatus += $NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$_.Status -ne $Item.Status}
        IF ($NetworkInfoSource | ? {$_.NicLabel -match $item.NicLabel} | ? {$_.Status -ne $Item.Status}) {
            $Found = $True
            }

        #MissingValues
        If (!($Found)) {
            $MissingValue += $Item | select NicLabel,Gateway,Mask,Status
            }
        }

    $Passed | % {$NetworkInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Network Info"
		    Property = $($_.NicLabel)
		    Value = "(IP): $($_.IP)<br/>(GateWay): $($_.Gateway)<br/>(Mask): $($_.Mask)<br/>(Connection): $($_.Status)"
	        Status = "Pass"
		    }
        }
    $WrongMaskValue | % {$NetworkInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Network Info"
		    Property = $($_.NicLabel)
		    Value = "(IP): $($_.IP)<br/>(GateWay): $($_.Gateway)<br/>(Mask): $($_.Mask)<br/>(Connection): $($_.Status)"
	        Status = "Fail Mask Incorrect"
		    }
        }
    $WrongGateWay | % {$NetworkInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Network Info"
		    Property = $($_.NicLabel)
		    Value = "(IP): $($_.IP)<br/>(GateWay): $($_.Gateway)<br/>(Mask): $($_.Mask)<br/>(Connection): $($_.Status)"
	        Status = $(If ($_.Gateway -eq "None Configured") {"Fail Gateway Missing"} Else {"Fail Gateway Unexpected"})
		    }
        }
    $WrongStatus | % {$NetworkInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Network Info"
		    Property = $($_.NicLabel)
		    Value = "(IP): $($_.IP)<br/>(GateWay): $($_.Gateway)<br/>(Mask): $($_.Mask)<br/>Connection State Expected: $($Item.Status)<br/>Connection State Found: $($_.Status)"
	        Status = "Failed"
		    }
        }
    $MissingValue | % {$NetworkInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Network Info"
		    Property = $($_.NicLabel)
		    Value = "(GateWay): $($_.Gateway)<br/>(Mask): $($_.Mask)<br/>(Connection): $($_.Status)"
	        Status = "Fail Missing"
		    }
        }

    #List the untested Elements
    $NetworkInfoUntested=@()
    ForEach ($Object in $NetworkInfoSource) {
        #Write-Host "Objects... $($Object.NicLabel) : $($Object.IP) : $($Object.Mask)"
        IF (!($NetworkInfoTest.Property -Contains $object.NicLabel -and $NetworkInfoTest.value -match $object.Mask -and $NetworkInfoTest.value -match $object.ip)) {
            Write-Host "NetworkInfo Not tested.... $($Object.NicLabel) : $($Object.IP) : $($Object.Mask)"
            $NetworkInfoUntested += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "Network Info"
			    Property = $($Object.NicLabel)
			    Value = "$($Object.IP) : $($Object.Gateway) : $($Object.Mask)"
	            Status = "Untested"
			    }
            }
        }

    $NetworkInfoTest+=$NetworkInfoUntested
    #End NetworkInfoInfo Compare

###################################

    #RouteInfo Tests
    Write-Host "RouteInfo Tests"
    $RouteInfoTest=@()
    $Passed=@()
    #$Failed=@()
    $WrongMaskValue=@()
    $WrongNicLabel=@()
    $MissingValue=@()

    ForEach ($Item in $RouteInfoComp) {
        $Found=$False
        [ref]$a=$null #required to validate ip address

        #Matched Items Expected and Correct
        $Nic=$null
        $passed+=$RouteInfoSource | ? {$_.Destination -match $item.Destination} | ? {$_.Mask -Eq $Item.Mask -and $_.NicLabel -Eq $Item.NicLabel}
        IF ($RouteInfoSource | ? {$_.Destination -match $item.Destination} | ? {$_.Mask -Eq $Item.Mask -and $_.NicLabel -Eq $Item.NicLabel}) {
            $Found=$True
            }

        #Matched NIC Labels and Mask but Default gateway either set or not set when it shouldn't or should be
        $WrongMaskValue+=$RouteInfoSource | ? {$_.Destination -match $item.Destination} | ? {$_.Mask -ne $Item.Mask}
        IF ($RouteInfoSource | ? {$_.Destination -match $item.Destination} | ? {$_.Mask -ne $Item.Mask}) {
            $Found=$True
            }

        #Matched NIC Labels but Mask different than expected
        $WrongNicLabel+=$RouteInfoSource | ? {$_.Destination -match $item.Destination} | ? {$_.NicLabel -ne $Item.NicLabel}
        IF ($RouteInfoSource | ? {$_.Destination -match $item.Destination} | ? {$_.NicLabel -ne $Item.NicLabel}) {
            $Found=$True
            }

        #MissingValues
        If (!($Found)) {
            $MissingValue+=$Item | select Destination,NicLabel,Gateway,Mask
            }
        }

    $Passed | % {$RouteInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Route Info"
		    Property = $($_.Destination)
		    Value = "(Nic): $($_.NicLabel)<br/>(Mask): $($_.Mask)"
	        Status = "Pass"
		    }
        }
    $WrongMaskValue | % {$RouteInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Route Info"
		    Property = $($_.Destination)
		    Value = "(Nic): $($_.NicLabel)<br/>(Mask): $($_.Mask)"
	        Status = "Fail Mask Incorrect"
		    }
        }
    $WrongNicLabel | % {$RouteInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Route Info"
		    Property = $($_.Destination)
		    Value = "(Nic): $($_.NicLabel)<br/>(Mask): $($_.Mask)"
	        Status = "Fail Wrong Interface"
		    }
        }
    $MissingValue | % {$RouteInfoTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Route Info"
		    Property = $($_.Destination)
		    Value = "(Nic): $($_.NicLabel)<br/>(Mask): $($_.Mask)"
	        Status = "Fail Missing"
		    }
        }

    #List the untested Elements

    $RouteInfoUntested=@()
    ForEach ($Object in $RouteInfoSource) {
        #Write-Host "Objects... $($Object.Destination) : $($Object.NicLabel) : $($Object.Mask)"
        IF (!($RouteInfoTest.Property -Contains $object.Destination -and $RouteInfoTest.value -match $object.NicLabel -and $RouteInfoTest.value -match $object.Mask)) {
            #Write-Host "RouteInfo Not tested.... $($Object.Destination) : $($Object.NicLabel) : $($Object.Mask)"
            $RouteInfoUntested += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "Route Info"
			    Property = $($Object.Destination)
			    Value = "(Nic): $($Object.NicLabel)<br/>(GateWay): $($Object.Gateway)<br/>(Mask): $($Object.Mask)"
	            Status = "Fail Unexpected"
			    }
            }
        }
    $RouteInfoTest+=$RouteInfoUntested
    #End RouteInfoInfo Compare

###################################

    #Host File Info Tests
    Write-Host "Host File Info Tests"
    $HostFileInfoTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    #If ($ProgramInfoSource -ne $Null) {
    If ($HostFileInfoSource) {
        Write-Host "Host File Info Tests....2"
        ForEach ($Item in $HostFileInfoComp) {
            $Found=$False
            $Passed=$Null
            $Failed=$Null
            $MissingValue=$Null

            #Program Correct
            If ($HostFileInfoSource | ? {$_.HostRecord -match $Item.HostRecord -and $_.IPAddress -match $Item.IPAddress}) {
                $Found=$True
                $passed=$HostFileInfoSource | ? {$_.HostRecord -match $Item.HostRecord -and $_.IPAddress -match $Item.IPAddress}
                $Passed | % { $HostFileInfoTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "HostFile"
		                Property = $($_.HostRecord)
		                Value = "$($_.IPAddress)"
	                    Status = "Pass"
		                }
                    }
                }
            #Program IncorrectCorrect
            If ($HostFileInfoSource | ? {$_.HostRecord -match $Item.HostRecord -and $_.IPAddress -notmatch $Item.IPAddress}) {
                $Found=$True
                $Failed = $HostFileInfoSource | ? {$_.HostRecord -match $Item.HostRecord -and $_.IPAddress -notmatch $Item.IPAddress}
                $Failed | % { $HostFileInfoTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "HostFile"
		                Property = $($_.HostRecord)
		                Value = "Configured: $($_.IPAddress)<br/>Expected: $($Item.IPAddress)"
	                    Status = "Fail: InCorrect Value"
		                }
                    }
                }

            #MissingValues mop up in case of unknowns
            If (!($Found)) {
                $MissingValue=$Item
                $MissingValue | % { $HostFileInfoTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "HostFile"
		                Property = $($_.HostRecord)
		                Value = "$($_.IPAddress)"
	                    Status = "Fail Missing"
		                }
                    }
                }

            }
        #List the untested Elements changed to unexpected for Mobile Connection Tests
        ForEach ($Object in $HostFileInfoSource ) {
            If (!($HostFileInfoTest.Property -Match $object.HostRecord -and $HostFileInfoTest.value -match $object.IPAddress)) {
                $HostFileInfoTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "HostFile"
		            Property = $($Object.HostRecord)
		            Value = "$($Object.IPAddress)"
	                Status = "Fail Unexpected"
			        }
                }
            }
        }
    #End HostFile Info Tests
    #>

###############################

    #DataDog Services Info
    Write-Host "DataDog Services Tests"
    $DataDogTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    $PreviousEnvironment = $Environment
    Switch ($Environment.Length) {
        {$_ -eq 7} {$Environment = $Environment.SubString(3,4)}
        {$_ -eq 9} {$Environment = $Environment.SubString(5,4)}
        #{$_ -eq 7 -and $Environment -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        default {$Environment = $Environment}
        }
    #23/01/22 (MH) - Hack for new environment name used in 2019 os
    If ( $os = "2019" ) { $Environment = $Environment.Replace("-1","") }

    Write-Host "DataDog Environment: $Environment"

    ForEach ($Item in ($DataDogServicesInfoComp) ) {
        $Found=$False
        $FailStatus=$Null
        $Passed=$Null
        $Failed=$Null
        $MissingValue=$Null
        #Serivce Correct
        IF ($DataDogSource | ? { $_.Name -match $Item.Name -and $_.State -match $Item.State -and $_.Startup -match $Item.Startup -and $_.RunAs -match [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)  } ) {
            $Found=$True
            $passed=$DataDogSource | ? { $_.Name -match $Item.Name -and $_.State -match $Item.State -and $_.Startup -match $Item.Startup -and $_.RunAs -match [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)}
            $Passed | % { $DataDogTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "DataDogService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($_.RunAs)"
	                Status = "Pass"
		            }
                }
            }

        #Serivce IncorrectCorrect
        IF ($DataDogSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) } ) {
            $Found=$True
            $Failed=$DataDogSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) }
            #$AppServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) } #| % {Write-Warning "Failed: Service -- $($_.Name)"}
            $FailureReason=$DataDogSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) }
            Switch ($FailureReason) {
                {$_.State -notmatch $Item.State} {
                    $FailStatus="State<br>"
                    }
                {$_.Startup -notmatch $Item.Startup} {
                    $FailStatus=$FailStatus+"Startup<br>"
                    }
                #23/01/22 (MH) - Hack for new environment name used in 2019 os
                #{$_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)} {
                {$_.RunAs -notmatch $(($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))} {
                    $FailStatus=$FailStatus+"Account<br>"
                    }
                }

            $Failed | % { $DataDogTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "DataDogService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($_.RunAs)"
	                Status = "Fail:<br/>$FailStatus"
		            }
                }
            }

        #MissingValues mop up in case of unknowns
        If (!($Found)) {
            $MissingValue=$Item | select Name, State, Startup, Runas
            $MissingValue | % { $DataDogTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "DataDogService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($($_.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))"
	                Status = "Fail Missing"
		            }
                }
            }

        }
    #List the untested Elements changed to unexpected for AppServices
    ForEach ($Object in $DataDogSource ) {
        If (!($DataDogTest.Property -Match $object.Name)) {
            $DataDogTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "DataDogService"
			    Property = $($Object.Name)
		        Value = "State: ($($Object.State))<br/>Startup: $($Object.Startup)<br/>RunAs: $($Object.RunAs)"
	            Status = "Fail Unexpected"
			    }
            }

    }

    If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
    #End DataDog Services Info

###############################

    #Virus dat Tests
    Write-Host "Virus dat Tests"
    $AntiVirusTest=@()
    $Passed=@()
    #$Failed=@()
    $WrongValue=@()
    $MissingValue=@()
    IF (Test-Path -Path Variable:\DatDate) {Clear-Variable DatDate}
    ForEach ($Item in $AntiVirusComp) {
        $Found=$False
        #Write-Host "Items -- $($Item.Name) : $($Item.'#text')"

        If ($Item.name -match "AntiVirus Dat Date") {
            Write-Host "Checking Dat Date"
            [datetime]$strdate = $reportdate
            $DatDate=(($AntiVirusSource | ? {$_.Name -eq "AntiVirus Dat Date"}).'#text')
            $ukCulture = [Globalization.cultureinfo]::GetCultureInfo("en-GB")
		    IF ($DatDate) {
			    [datetime]$DatDateDT=[datetime]::Parse($DatDate, $ukculture)
		        If ($strdate.AddDays(-5) -le $DatDateDT) {
                    #Write-Host "Dat is less than five days old"; $strdate; $DatDateDT
                    $Found=$True
                    $AntiVirusTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "Anti Virus Info"
		                Property = $($Item.Name)
		                Value = $DatDateDT
	                    Status = "Pass"
		                }
                    }
                Else {
                    $Found=$True
                    $AntiVirusTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "Anti Virus Info"
		                Property = $($Item.Name)
		                Value = $DatDateDT
	                    Status = "Fail Dat too old"
		                }
                    }
			    }
            ELSE {
                $Found=$True
                $AntiVirusTest += New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Test = "Anti Virus Info"
		            Property = $($Item.Name)
		            Value = $DatDateDT
	                Status = "Fail Dat date unknown"
		            }
                }
            }

     #   If ( $Item.name -match "CrowdStrike Grouping Tag" ) {
            #$passed+=$AntiVirusSource | ? {$_.Name -match $item.Name} | ? {$_.'#text' -Eq $Item.'#text'}
            $passed+=$AntiVirusSource | ? {$_.Name -match $item.Name} | ? {[Regex]::Escape($_.'#text') -Eq [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment)}
            If ($AntiVirusSource | ? {$_.Name -match $item.Name} | ? {[Regex]::Escape($_.'#text') -Eq [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment)}) {
                $Found=$True
                }

            #Matched Item but value different
            #$WrongValue+=$AntiVirusSource | ? {$_.Name -match $item.Name} | ? {$_.'#text' -ne $Item.'#text' -and !$Found}
            $WrongValue+=$AntiVirusSource | ? {$_.Name -match $item.Name} | ? {[Regex]::Escape($_.'#text') -ne [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment) -and !$Found}
            If ($AntiVirusSource | ? {$_.Name -match $item.Name} | ? {[Regex]::Escape($_.'#text') -ne [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment) -and !$Found}) {
                $Found=$True
                }

            #MissingValues
            If (!($Found)) {
                $MissingValue+=$Item
                }
         #   }

   <#     Else {

            #Matched Items Expected and Correct
            $passed+=$AntiVirusSource | ? {$_.Name -match $item.Name} | ? {$_.'#text' -Eq $Item.'#text'}
            IF ($AntiVirusSource | ? {$_.Name -match $item.Name} | ? {$_.'#text' -Eq $Item.'#text'}) {
                $Found=$True
                }

            #Matched Item but value different
            $WrongValue+=$AntiVirusSource | ? {$_.Name -match $item.Name} | ? {$_.'#text' -ne $Item.'#text' -and !$Found}
            IF ($AntiVirusSource | ? {$_.Name -match $item.Name} | ? {$_.'#text' -ne $Item.'#text' -and !$Found}) {
                $Found=$True
                }

            #MissingValues
            If (!($Found)) {
                $MissingValue+=$Item
                }
            } #>
        }

    $Passed | % {$AntiVirusTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Anti Virus Info"
		    Property = $($_.Name)
		    Value = "$($_.'#text')"
	        Status = "Pass"
		    }
        }
    $WrongValue | % {$AntiVirusTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Anti Virus Info"
		    Property = $($_.Name)
		    Value = "$($_.'#text')"
	        Status = "Fail Wrong Value"
		    }
        }
    $MissingValue | % {$AntiVirusTest += New-Object -TypeName PSObject -Property @{
            Server = $Server
            Test = "Anti Virus Info"
		    Property = $($_.Name)
		    Value = "$($_.'#text')"
	        Status = "Fail Missing"
		    }
        }

    #List the untested Elements
    $AntiVirusUntested=@()
    ForEach ($Object in $AntiVirusSource) {
        #Write-Host "Objects... $($Object.Name) : $($Object.'#text')"
        IF ((!($AntiVirusTest.Property -Contains $object.name -and $AntiVirusTest.value -match $object.'#text') -and $Object.Name -ne "AntiVirus Dat Date")) {
            #Write-Host "Anti Virus Not tested.... $($Object.name) : $($Object.'#text')"
            $AntiVirusUntested += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "Anti Virus Info"
		        Property = $($Object.Name)
		        Value = $($Object.'#text')
	            Status = "Untested"
			    }
            }
        }
    $AntiVirusTest+=$AntiVirusUntested
    #End Anti Virus Compare

####################################################

#Monitorin Services Info
    Write-Host "Monitoing Services Tests"
    Write-Host "Pre Monitoring Info Environment: $Environment"

    $MonitoringServicesTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    $PreviousEnvironment = $Environment
    Switch ($Environment.Length) {
        {$_ -eq 7} {$Environment = $Environment.SubString(3,4)}
        {$_ -eq 9} {$Environment = $Environment.SubString(5,4)}
        #{$_ -eq 7 -and $Environment -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        default {$Environment = $Environment}
        }
    #23/01/22 (MH) - Hack for new environment name used in 2019 os
    If ( $os = "2019" ) { $Environment = $Environment.Replace("-1","") }

    Write-Host "Monitoring Environment: $Environment"

#    ForEach ($Item in ($TelegrafServicesInfoComp | ? {$_.Site -eq $Site -or $_.Site -eq "All"}) ) {
    ForEach ($Item in ($MonitoringServicesInfoComp | ? {$_.Site -eq $Site -or $_.Site -eq "All"}) ) {
        $Found=$False
        $FailStatus=$Null
        $Passed=$Null
        $Failed=$Null
        $MissingValue=$Null
        #Service Correct
        IF ($MonitoringServicesSource | ? { $_.Name -match $Item.Name -and $_.State -match $Item.State -and $_.Startup -match $Item.Startup -and $_.RunAs -match [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)  } ) {
            $Found=$True
            $passed=$MonitoringServicesSource | ? { $_.Name -match $Item.Name -and $_.State -match $Item.State -and $_.Startup -match $Item.Startup -and $_.RunAs -match [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)}
            $Passed | % { $MonitoringServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "MonitoringService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($_.RunAs)"
	                Status = "Pass"
		            }
                }
            }

        #Serivce IncorrectCorrect
        IF ($MonitoringServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) } ) {
            $Found=$True
            $Failed=$MonitoringServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) }
            #$AppServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) } #| % {Write-Warning "Failed: Service -- $($_.Name)"}
            $FailureReason=$MonitoringServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) }
            Switch ($FailureReason) {
                {$_.State -notmatch $Item.State} {
                    $FailStatus="State<br>"
                    }
                {$_.Startup -notmatch $Item.Startup} {
                    $FailStatus=$FailStatus+"Startup<br>"
                    }
                {$_.RunAs -notmatch $(($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))} {
                    $FailStatus=$FailStatus+"Account<br>"
                    }
                }

            $Failed | % { $MonitoringServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "MonitoringService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($_.RunAs)"
	                Status = "Fail:<br/>$FailStatus"
		            }
                }
            }

        #MissingValues mop up in case of unknowns
        If (!($Found)) {
            $MissingValue=$Item | select Name, State, Startup, Runas
            $MissingValue | % { $MonitoringServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "MonitoringService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($($_.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))"
	                Status = "Fail Missing"
		            }
                }
            }

        }
    #List the untested Elements changed to unexpected for TelegrafServices
    ForEach ($Object in $MonitoringServicesSource ) {
        If (!($MonitoringServicesTest.Property -Match $object.Name)) {
            $MonitoringServicesTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "MonitoringService"
			    Property = $($Object.Name)
		        Value = "State: ($($Object.State))<br/>Startup: $($Object.Startup)<br/>RunAs: $($Object.RunAs)"
	            Status = "Fail Unexpected"
			    }
            }
        }
    If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
    Write-Host "Post Monitoring Info Environment: $Environment"

    #End Monitoring Services

####################################################

    #SQL Information Tests
    Write-Host "SQL Information Tests"
    $SQLInfoTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    $PreviousEnvironment = $Environment

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    Switch ($Environment) {
        {$_ -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        {$_ -match "GP" -and $Server -match "-LS|-LF"} {$Environment = $Server.Replace("-","_").replace('LS','').replace('LF','')}
        ##23/01/22 (MH) - Hack for new environment name used in 2019 os
        {$_ -match "GP" -and $Server -match "ENLSGP-|ENLFGP-"} {$Environment = $Server.Replace("-","_").replace('LS','').replace('LF','')}
		##19/07/22 (CM) - Attempted hack for new CCMH environment names used in 2019 os
        {$_ -match "GP" -and $Server -match "CMLSGP-|CMLFGP-"} {$Environment = $Server.Replace("-","_").replace('LS','').replace('LF','')}
        {$Server -match "ENEUW2GP"} {$Environment = $Server.Substring(0,10).Replace('DBS01','').replace('DBS02','').replace('RS-01','')}
        #{($_.SubString(0,6) -Match "ENEUW2")} {$Environment = $Server.SubString(6,4); $SQLEnvironment = 'MSSQLSERVER'<#$Server.Replace("-","_").replace('LS','').replace('LF','')!#>; $CLSEnvironment = $Server.Substring(0,11).Replace('DBS01','DB').replace('DBS02','DB')}

        default {$Environment = $Environment}
        }

    ForEach ($Item in $SQLInfoComp) {
        Switch ($ServerType) {
            {$_ -eq "OneBoxCombi"} {$SQLEnvironmentInfo = $Server}
            Default {$SqlEnvironmentInfo = $Environment}
            }
        $SqlInfSource=$Null
        $SqlInfComp=$Null
        $SQLInstance=$Null
        If ($SQLInfoSource.Instance -match $($Item.Instance.Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo)) ) {
            $SqlInfSource=($SQLInfoSource | ? {$_.Instance -match $($Item.Instance.Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo))}).property
            $SqlInfComp=$($Item).property
            $SQLInstance=$($Item.Instance.Replace('XXENVIRONMENTXX',$SQLEnvironment).Replace('XXDOMAINXX',$Domain))

            ForEach ($SQLInfo in $SqlInfComp) {
                $Found=$False
                #Matched
                IF ($SQLInfSource | ? {$_.Setting -match [Regex]::Escape($SQLInfo.Setting).Replace('XXENVIRONMENTXX',$SQLEnvironmentIno) -and $_.'#text' -match [Regex]::Escape($SQLInfo.'#text').Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo)} ) {
                    $Passed+=$SQLInfSource | ? {$_.Setting -match [Regex]::Escape($SQLInfo.Setting).Replace('XXENVIRONMENTXX',$SQLEnvironmentIno) -and $_.'#text' -match [Regex]::Escape($SQLInfo.'#text').Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo)}
                    $Found=$True
                    }
                #Matched but wrong value
                IF ($SQLInfSource | ? {$_.Setting -match [Regex]::Escape($SQLInfo.Setting).Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo) -and $_.'#text' -notmatch [Regex]::Escape($SQLInfo.'#text').Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo)} ) {
                    $WrongValue+=$SQLInfSource | ? {$_.Setting -match [Regex]::Escape($SQLInfo.Setting).Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo) -and $_.'#text' -notmatch [Regex]::Escape($SQLInfo.'#text').Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo)}
                    $Found=$True
                    }
                #not found
                IF (!$Found -and $SQLInfSource | ? {;$_.Setting -notmatch [Regex]::Escape($SQLInfo.Setting).Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo)} ) {
                    $Found=$True
                    $Failed+=$SQLInfo | select Setting, '#text'.tostring().Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo)
                    }
                #mop up in case of unknowns
                If (!($Found)) {
                    $MissingValue+=$Item | select Setting, '#text'.tostring().Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo)
                    #$MissingValue=$MissingValue | % {$_.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)}
                    Write-Warning "Item Not Found!! -- $($Item.group) : $($Item.'#text'.Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo))"
                    }
                }
            $Passed | % { $SQLInfoTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlInfo"
		            Property = $SQLInstance
		            Value = "($($_.Setting)) $($_.'#text')"
	                Status = "Pass"
		            }
                }
            $WrongValue | % { $SQLInfoTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlInfo"
		            Property = $SQLInstance
		            Value = "($($_.Setting)) $($_.'#text')"
	                Status = "Fail Wrong Value"
		            }
                }
            $Failed | % { $SQLInfoTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlInfo"
		            Property = $SQLInstance
		            Value = "($($_.Setting)) $($_.'#text'.Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo))"
	                Status = "Failed Missing"
		            }
                }
            $MissingValue | % { $SQLInfoTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlInfo "
		            Property = $SQLInstance
		            Value = "($($_.Setting)) $($_.'#text'.Replace('XXENVIRONMENTXX',$SQLEnvironmentInfo))"
	                Status = "Fail Missing"
		            }
                }

            #List the untested Elements changed to unexpected for SqlInformation
            ForEach ($Object in $SQLInfSource ) {
                IF (!($SQLInfoTest.Value -Match [Regex]::Escape($object.Setting) -and $SQLInfoTest.value -Match [Regex]::Escape($object.'#text'))) {
                    #Write-Warning "$($Object.Setting) unexpected....  $($Object.'#text')"
                    $SQLInfoTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "SqlLogin"
			            Property = $SQLInstance
			            Value = "($($Object.Setting)) $($Object.'#text')"
	                    Status = "Fail Unexpected"
			            }
                    }
                }

            }

        }
    If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
    Write-Host "Post SQL Info Environment: $Environment"

    #End SQL Information Compare

################################################

    #SQL Logins Info
    Write-Host "SQL Login Tests"
    $SQLLoginTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    $PreviousEnvironment = $Environment

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    Switch ($Environment.Length) {
        {$_ -eq 7} {$Environment = $Environment.SubString(3,4)}
        {$_ -eq 9} {$Environment = $Environment.SubString(5,4)}
        #{$_ -eq 7 -and $Environment -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        default {$Environment = $Environment}
        }
    #23/01/22 (MH) - Hack for new environment name used in 2019 os
    If ( $os = "2019" ) { $Environment = $Environment.Replace("-","_") }

    Write-Host "SQL Temp Env: $Environment"


    ForEach ($Item in $SQLLoginsInfoComp) {
        Write-Host "SQL Login Env2: $Environment"
        $SqlLoginSource=$Null
        $SqlLoginInfoComp=$Null
        $SQLInstance=$Null
        If ( ($SQLLoginsSource.Instance -match $($Item.Instance.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))) -OR ($SQLLoginsSource.Instance -match $($Item.Instance.Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain))) ) {
            Switch ($Environment) {
                {$_ -match "EN-GP"} {
                    $SqlLoginSource=($SQLLoginsSource | ? {$_.Instance -match $($Item.Instance.Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain))}).property
                    $SQLInstance=$($Item.Instance.Replace('XXENVIRONMENTXX',$($Server.Replace('-','_'))).Replace('XXDOMAINXX',$Domain))
                    $SQLInstance=$($Item.Instance.Replace('XXENVIRONMENTXX',$SQLEnvironment).Replace('XXDOMAINXX',$Domain))
                    }
                default {
                    $SqlLoginSource=($SQLLoginsSource | ? {$_.Instance -match $($Item.Instance.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))}).property
                    #$SQLInstance=$($Item.Instance.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))
                    $SQLInstance=$($Item.Instance.Replace('XXENVIRONMENTXX',$SQLEnvironment).Replace('XXDOMAINXX',$Domain))
                    }
                }

            $SqlLoginInfoComp=$($Item).property

            #23/01/22 (MH) - Hack for new environment name used in 2019 os
            If ( $os = "2019" ) { $Environment = $Environment.Replace("_1","") }

            ForEach ($Login in $SqlLoginInfoComp) {
                $Found=$False
                #Matched allowed logins
                IF ($SQLLoginSource | ? {$_.Type -match [Regex]::Escape($Login.Type).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) -and $_.'#text' -match [Regex]::Escape($login.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)} ) {
                    $Passed+=$SQLLoginSource | ? {$_.Type -match [Regex]::Escape($Login.Type).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) -and $_.'#text' -match [Regex]::Escape($login.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)}
                    $Found=$True
                    }
                #Login not found
                IF (!$Found -and $SQLLoginSource | ? {$_.Type -notmatch [Regex]::Escape($Login.Type).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) -and $_.'#text' -notmatch [Regex]::Escape($login.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)} ) {
                    $Found=$True
                    $Failed+=$Login | select type, '#text'.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)
                    }
                #MissingValues mop up in case of unknowns
                If (!($Found)) {
                    $MissingValue+=$Item | select type, '#text'.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)
                    }
                }
            $Passed | % { $SQLLoginTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlLogin"
		            Property = $SQLInstance
		            Value = "($($_.type)) $($_.'#text')"
	                Status = "Pass"
		            }
                }
            $Failed | % { $SQLLoginTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlLogin"
		            Property = $SQLInstance
		            Value = "($($_.type)) $($_.'#text'.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))"
	                Status = "Failed Missing"
		            }
                }
            $MissingValue | % { $SQLLoginTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlLogin"
		            Property = $SQLInstance
		            Value = "($($_.type)) $($_.'#text'.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))"
	                Status = "Fail Missing"
		            }
                }

            #List the untested Elements changed to unexpected for SqlLogins
            ForEach ($Object in $SQLLoginSource ) {
                IF (!($SQLLoginTest.Value -Match [Regex]::Escape($object.Type) -and $SQLLoginTest.value -Match [Regex]::Escape($object.'#text'))) {
                    $SQLLoginTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "SqlLogin"
			            Property = $SQLInstance
			            Value = "($($Object.type)) $($Object.'#text')"
	                    Status = "Fail Unexpected"
			            }
                    }
                }

            }

        }

        If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
        Write-Host "Post SQL Login Tests Environment: $Environment"
    #End Sql Logins

#####################################################

    #SQL Access Info
    Write-Host "SQL Access Tests"
    $SQLAccessTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    $PreviousEnvironment = $Environment

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    Switch ($Environment.Length) {
        {$_ -eq 7} {$Environment = $Environment.SubString(3,4)}
        {$_ -eq 9} {$Environment = $Environment.SubString(5,4)}
        #{$_ -eq 7 -and $Environment -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        default {$Environment = $Environment}
        }
    #23/01/22 (MH) - Hack for new environment name used in 2019 os
    If ( $os = "2019" ) { $Environment = $Environment.Replace("-","_") }

    $SQLAccessInfoSource.Instance

    ForEach ($Item in $SQLAccessComp) {
        $SqlAccessItemSource=$Null
        $SqlAccessItemComp=$Null
        $SQLInstance=$Null
        If ($SQLAccessSource.Instance -match $($Item.Instance.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)) ) {
            $SqlAccessItemSource=($SQLAccessSource | ? {$_.Instance -match $($Item.Instance.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server))}).property
            $SqlAccessItemComp=$($Item).property
#            $SQLInstance=$($Item.Instance.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server))
            $SQLInstance=$($Item.Instance.Replace('XXENVIRONMENTXX',$SQLEnvironment).Replace('XXDOMAINXX',$Domain))

            ForEach ($Access in $SqlAccessItemComp) {
                $Found=$False
                If ( $($Access.'#text') -match "NT Service" -AND $($Access.'#text') -match "XXENVIRONMENTXX") {
                    #06/06/2016 hack for new naming environment
                    If ($Server -match "-LS|-LF" ) {
                        #Write-Host "Access -- $($Access.Role) : $($($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_').Replace('LS','').Replace('LF',''))).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server))"
                        }
                    Else {
                        #Write-Host "Access -- $($Access.Role) : $($($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server))"
                        }
                    #Matched allowed Access
                    #IF ($SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) } ) {
                    #IF ($SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and ( $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_').Replace('LS','').Replace('LF',''))).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) ) } ) {
                    IF ($SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and ( $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_').Replace('LS','').Replace('LF',''))).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Server).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) ) } ) {

                        #$Passed+=$SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and ( $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_').Replace('LS','').Replace('LF',''))).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) )}
                        $Passed+=$SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and ( $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_').Replace('LS','').Replace('LF',''))).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Server).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) )}
                        $Found=$True
                        #$SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and ( $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_').Replace('LS','').Replace('LF',''))).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) )} | % {Write-Host "Group Present -- $($Instance) : $($_.Role) : $($_.'#text')"}
                        $SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and ( $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_').Replace('LS','').Replace('LF',''))).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -OR $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Server).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) )} | % {Write-Host "Group Present -- $($Instance) : $($_.Role) : $($_.'#text')"}
                        }
                    #Login not found
                    IF (!$Found -and $SQLAccessItemSource | ? {$_.Role -notmatch [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and $_.'#text' -notmatch [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)} ) {
                        $Found=$True
                        Write-Warning "Missing -- $($($Access.'#text').Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server))"
                        $Failed+=$Access | select role, '#text'.tostring().Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)
                        }
                    #MissingValues mop up in case of unknowns
                    If (!($Found)) {
                        $MissingValue+=$Access | select role, '#text'.tostring().Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)
                        #$MissingValue=$MissingValue | % {$_.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)}
                        Write-Warning "Item Not Found!! -- $($Access.role) : $($Access.'#text'.Replace('XXENVIRONMENTXX',$($Server.Replace('-','_')).substring(2)).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server))"
                        }
                    }
                Else {
                    #Matched allowed Access
                    #23/01/22 (MH) - Hack for new environment name used in 2019 os
                    $PreviousAlteredEnvironment = $Environment
                    If ( $os = "2019" ) { $Environment = $Environment.Replace("_1","") }
                    IF ($SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)} ) {
                        $Passed+=$SQLAccessItemSource | ? {$_.Role -match [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and $_.'#text' -match [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)}
                        $Found=$True
                        }
                    #Login not found
                    IF (!$Found -and $SQLAccessItemSource | ? {$_.Role -notmatch [Regex]::Escape($Access.Role).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server) -and $_.'#text' -notmatch [Regex]::Escape($Access.'#text').Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)} ) {
                        $Found=$True
                        #23/01/22 Hacking around for new naming convention
                        $obj = New-Object -TypeName PSObject -Property @{
                            Role = $Access.Role
                            '#text' = $Access.'#text'.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)
                            }
                        $Failed += $obj
                        #$Failed+=$Access | select role,'#text'.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)
                        }
                    #MissingValues mop up in case of unknowns
                    If (!($Found)) {
                        #23/01/22 Hacking around for new naming convention
                        $obj = New-Object -TypeName PSObject -Property @{
                            Role = $Access.Role
                            '#text' = $Access.'#text'.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)
                            }
                        $MissingValue += $obj
                        #$MissingValue+=$Access | select role, '#text'.tostring().Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server)
                        }
                    #23/01/22 (MH) - Hack for new environment name used in 2019 os
                    If (Test-Path -Path Variable:\PreviousAlteredEnvironment) {$Environment=$PreviousAlteredEnvironment}
                    }

                }
            $Passed | % { $SQLAccessTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlAccess"
		            Property = $SQLInstance
		            Value = "($($_.Role)) $($_.'#text')"
	                Status = "Pass"
		            }
                }
            $Failed | % { $SQLAccessTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlAccess"
		            Property = $SQLInstance
		            Value = "($($_.Role)) $($_.'#text'.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server))"
	                Status = "Failed Missing"
		            }
                }
            $MissingValue | % { $SQLAccessTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SqlAccess"
		            Property = $SQLInstance
		            Value = "($($_.Role)) $($_.'#text'.Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain).Replace('XXSERVERXX',$Server))"
	                Status = "Fail Missing"
		            }
                }

            #List the untested Elements changed to unexpected for SqlLogins
            ForEach ($Object in $SQLAccessItemSource ) {
                IF (!($SQLAccessTest.Value -Match [Regex]::Escape($object.type) -and $SQLAccessTest.value -Match [Regex]::Escape($object.'#text'))) {
                    $SQLAccessTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "SqlAccess"
			            Property = $SQLInstance
			            Value = "($($Object.Role)) $($Object.'#text')"
	                    Status = "Fail Unexpected"
			            }
                    }
                }

            }

        }
    If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
    Write-Host "Post SQL Access Environment: $Environment"

    #End Access Logins

###############################

#<#
#SQL Service SPN Info
    Write-Host "SQL Service SPN Tests"
    $SQLServiceSPNsTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()
    $FailedCount=0

    $PreviousEnvironment = $Environment

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    Switch ($Environment.Length) {
        {$_ -eq 7} {$Environment = $Environment.SubString(3,4)}
        {$_ -eq 9} {$Environment = $Environment.SubString(5,4)}
        {$_ -eq 10} {$Environment = $Environment.SubString(6,4)}
        #{$_ -eq 7 -and $Environment -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        default {$Environment = $Environment}
        }
    #23/01/22 (MH) - Hack for new environment name used in 2019 os
    If ( $os = "2019" ) { $V0Environment = $Environment.Replace("-1","") }
    If ( $os = "2019" ) { $Environment = $Environment.Replace("-","_") }

    Write-Host "Altered Environment: $Environment"

    ForEach ( $Item in $SQLServiceSPNsInfoComp ) {
        $Found = $False
        #$Item
        #If ( $SQLServiceSPNsSource | ? { $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:*$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" -and $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) } ) {
        #If ( $SQLServiceSPNsSource | ? { $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) -and $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" } ) {
        If ( $SQLServiceSPNsSource | ? { $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) -and ( $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" -OR $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:1433" ) } ) {
            $Found = $True
            #$Passed += $SQLServiceSPNsSource | ? { $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) -and $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" }
            $Passed += $SQLServiceSPNsSource | ? { $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) -and ( $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" -OR $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:1433" ) }
            $Passed | % { $SQLServiceSPNsTest += New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Test = "SQLServiceSPN"
		            Property = $($_.ServiceAccount)
		            Value = "$($_.SPN)"
	                Status = "Pass"
		            }
                }
            #Write-Host "Passed"
            }
        #If ( $SQLServiceSPNsSource | ? { $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:*$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" -and $_.ServiceAccount -notmatch $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) } ) {
        #If ( $SQLServiceSPNsSource | ? { $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) -and $_.SPN -notlike "MSSQLSvc/$($Server).$($Domain)*:$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" } ) {
        If ( $SQLServiceSPNsSource | ? { $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) -and ( $_.SPN -notlike "MSSQLSvc/$($Server).$($Domain)*:$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" -and $_.SPN -notlike "MSSQLSvc/$($Server).$($Domain)*:1433" ) } ) {
            #$Found = $True
            #$Failed += $SQLServiceSPNsSource | ? { $_.SPN -like "MSSQLSvc/$($Server).$($Domain)*:*$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" -and $_.ServiceAccount -notmatch $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) }
            #$Failed += $SQLServiceSPNsSource | ? { $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) -and $_.SPN -notlike "MSSQLSvc/$($Server).$($Domain)*:$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" }
            $Failed += $SQLServiceSPNsSource | ? { $_.ServiceAccount -match $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment) -and ( $_.SPN -notlike "MSSQLSvc/$($Server).$($Domain)*:$($Item.SPN.Replace('XXENVIRONMENTXX',$Environment))*" -and $_.SPN -notlike "MSSQLSvc/$($Server).$($Domain)*:1433" ) }
            $Failed | % { $SQLServiceSPNsTest += New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Test = "SQLServiceSPN"
		            Property = $($_.ServiceAccount)
		            Value = "Configured: $($_.SPN)</br>Expected: MSSQLSvc/&lt;ServerName&gt;.&lt;DomainFQDN&gt;:&lt;SQLInstance&gt;"
		            #Value = "Expected: MSSQLSvc/<ServerName>.<DomainFQDN>:<SQLInstance>"
	                Status = "Failed"
		            }
                }
            $FailedCount++ #Set this on the first failed so that the missing routing isn't continually invoked
            #Write-Host "Failed"
            }
        If ( !($Found) -And $FailedCount -le 1 ) {
            $MissingValue = $Item
            $MissingValue | % { $SQLServiceSPNsTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "SQLServiceSPN"
		            Property = $($Item.ServiceAccount).Replace('XXENVIRONMENTXX',$V0Environment)
		            Value = "MSSQLSvc/&lt;ServerName&gt;.&lt;DomainFQDN&gt;:&lt;SQLInstance&gt;"
	                Status = "Fail Missing"
		            }
                }
            #Write-Host "Missing"
            }
        #Write-Host "Found: $Found"
        }
    If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
    Write-Host "Env post SPNs: $($Environment)"
#SQL Service SPN Info END
#>

####################################
    #31/03/16 (MH) - Added the following section for Cluster Checks
    Write-Host "Cluster Checks"
    $ClusterChecksTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    #24/01/22 - fudge for new naming convention
    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    If ($ClusterInfoSource -ne $Null) {

        #Fix 10th October 2017
        #If ($environment -match "-LS|-LF") {
        If ($SQLEnvironment -match "-LS|-LF") {
            $PreviousEnvironment = $Environment
            #Fix 10th October 2017
            #$Environment = $Environment.replace('LS','').replace('LF','')
            $Environment = $SQLEnvironment.replace('LS','').replace('LF','')
            }
        If ($SQLEnvironment -match "EN-GP|EM-EC|NI-GP") {
            $PreviousEnvironment = $Environment
            $Environment = $SQLEnvironment
            }

        #24/01/22 - fudge for new naming convention
        $PreviousEnvironment = $Environment
        #$Environment = $CLSEnvironment

        ForEach ($Item in $ClusterInfoComp) {
            $Found=$False
            $Passed=$Null
            $Failed=$Null
            $MissingValue=$Null
            #Commented out, prevents crap output
            #$ClusterInfoSource | ? {$_.Name -match [Regex]::Escape($Item.name).Replace('XXENVIRONMENTXX',$Environment) -and $_.'#text' -match [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment)}

            #Cluster Correct
            IF ($ClusterInfoSource | ? {$_.Name -match [Regex]::Escape($Item.Name).Replace('XXENVIRONMENTXX',$Environment) -and $_.'#text' -match [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment)}) {
                $Found=$True
                $passed=$ClusterInfoSource | ? { $_.Name -match [Regex]::Escape($Item.Name).Replace('XXENVIRONMENTXX',$Environment) -and $_.'#text' -match [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment)}
                $Passed | % { $ClusterChecksTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "Cluster Checks"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Pass"
		                }
                    }
                }
            #Cluster Incorrect
            IF ($ClusterInfoSource | ? {$_.Name -match [Regex]::Escape($Item.Name).Replace('XXENVIRONMENTXX',$Environment) -and $_.'#text' -notmatch [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment)}) {
                $Found=$True
                $Failed=$ClusterInfoSource | ? { $_.Name -match [Regex]::Escape($Item.Name).Replace('XXENVIRONMENTXX',$Environment) -and $_.'#text' -notmatch [Regex]::Escape($Item.'#text').Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment)}
                $Failed | % { $ClusterChecksTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "Cluster Checks"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Fail: InCorrect Value"
		                }
                    }
                }

            #MissingValues mop up in case of unknowns
            If ($Found -ne $True) {
                $MissingValue=$Item
                $MissingValue | % { $ClusterChecksTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "Cluster Checks"
		                #24/01/22 - fudge for new naming convention
                        #Property = $($_.Name)
		                #Value = "$($_.'#text')"
	                    Property = $($($_.Name).Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment))
		                Value = "$($_.'#text'.Replace('XXDOMAINXX',$Domain).Replace('XXENVIRONMENTXX',$Environment))" #"$($_.'#text')"
	                    Status = "Fail Missing"
		                }
                    }
                }

            }

        #List the untested Elements changed to unexpected for Cluster Tests
        ForEach ($Object in $ClusterInfoSource ) {
            IF (!($ClusterChecksTest.Property -Match [Regex]::Escape($($object.Name)))) {
                $ClusterChecksTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "Cluster Checks"
			        Property = $($Object.Name)
		            Value = "$($Object.'#text')"
	                Status = "Fail Unexpected"
			        }
                }
            }
        }
        If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
        Write-Host "Post Cluster Environment: $Environment"


#End Cluster Tests

###################################################
#31/03/16 (MH) - Added the following section for DB Checks

    $DBChecksTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    If ($DBChecksSource -ne $Null) {
        ForEach ($Item in $DBChecksInfoComp) {
            Write-Host "DB Checks"
            $Found=$False
            $Passed=$Null
            $Failed=$Null
            $MissingValue=$Null

            $DBChecksSource | ? {$_.Name -match [Regex]::Escape($Item.'#text') -and $_.'#text' -match [Regex]::Escape($Item.'#text')}

            #DB Correct
            IF ($DBChecksSource | ? {$_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -match $Item.'#text'}) {
                $Found=$True
                $passed=$DBChecksSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -match $Item.'#text'}
                $Passed | % { $DBChecksTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "DB Checks"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Pass"
		                }
                    }
                }
            #DB Incorrect
            IF ($DBChecksSource | ? {$_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -notmatch $Item.'#text'}) {
                $Found=$True
                $Failed=$DBChecksSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -notmatch $Item.'#text'}
                $DBChecksSource | ? {$_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -notmatch $Item.'#text'} | % {Write-Warning "Failed: DBChecks -- $($_.Name) : $($_.'#text')"}

                $Failed | % { $DBChecksTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "DB Checks"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Fail: InCorrect Value"
		                }
                    }
                }

            #MissingValues mop up in case of unknowns
            If ($Found -ne $True) {
                $MissingValue=$Item
                Write-Warning "Item Not Found!! -- $($Item.Name) : $($Item.'#text')"

                $MissingValue | % { $DBChecksTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "DB Checks"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Fail Missing"
		                }
                    }
                }

            }
        #Write-Host "...."
        #List the untested Elements changed to unexpected for DB Tests
        ForEach ($Object in $DBChecksSource ) {
            IF (!($DBChecksTest.Property -Match [Regex]::Escape($($object.Name)))) {
                Write-Warning "$($Object.name) unexpected....  $($Object.'#text')"
                $DBChecksTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "DB Checks"
			        Property = $($Object.Name)
		            Value = "$($Object.'#text')"
	                Status = "Fail Unexpected"
			        }
                }
            }
            If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
            Write-Host "Post DB Checks Environment: $Environment"

        }
#End DBChecks Tests

######################################################################################

    #NetBackup Services Info
    Write-Host "Netbackup Services Tests"
    $NetBackupServicesTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    $PreviousEnvironment = $Environment
    Switch ($Environment.Length) {
        {$_ -eq 7} {$Environment = $Environment.SubString(3,4)}
        {$_ -eq 9} {$Environment = $Environment.SubString(5,4)}
        #{$_ -eq 7 -and $Environment -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        default {$Environment = $Environment}
        }
    #23/01/22 (MH) - Hack for new environment name used in 2019 os
    If ( $os = "2019" ) { $Environment = $Environment.Replace("-1","") }

    Write-Host "Netbackup Environment: $Environment"

    #ForEach ($Item in ($NetBackupServicesInfoComp | ? {$_.Site -eq $Site -or $_.Site -eq "All"}) ) {
    ForEach ($Item in ($NetBackupServicesInfoComp) ) {
        $Found=$False
        $FailStatus=$Null
        $Passed=$Null
        $Failed=$Null
        $MissingValue=$Null
        #Serivce Correct
        IF ($NetBackupServicesSource | ? { $_.Name -match $Item.Name -and $_.State -match $Item.State -and $_.Startup -match $Item.Startup -and $_.RunAs -match [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)  } ) {
            $Found=$True
            $passed=$NetBackupServicesSource | ? { $_.Name -match $Item.Name -and $_.State -match $Item.State -and $_.Startup -match $Item.Startup -and $_.RunAs -match [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)}
            $Passed | % { $NetBackupServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "NetBackupService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($_.RunAs)"
	                Status = "Pass"
		            }
                }
            }

        #Serivce IncorrectCorrect
        IF ($NetBackupServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) } ) {
            $Found=$True
            $Failed=$NetBackupServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) }
            #$AppServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) } #| % {Write-Warning "Failed: Service -- $($_.Name)"}
            $FailureReason=$NetBackupServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) }
            Switch ($FailureReason) {
                {$_.State -notmatch $Item.State} {
                    $FailStatus="State<br>"
                    }
                {$_.Startup -notmatch $Item.Startup} {
                    $FailStatus=$FailStatus+"Startup<br>"
                    }
                #23/01/22 (MH) - Hack for new environment name used in 2019 os
                #{$_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)} {
                {$_.RunAs -notmatch $(($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))} {
                    $FailStatus=$FailStatus+"Account<br>"
                    }
                }

            $Failed | % { $NetBackupServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "NetBackupService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($_.RunAs)"
	                Status = "Fail:<br/>$FailStatus"
		            }
                }
            }

        #MissingValues mop up in case of unknowns
        If (!($Found)) {
            $MissingValue=$Item | select Name, State, Startup, Runas
            $MissingValue | % { $NetBackupServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "NetBackupService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($($_.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))"
	                Status = "Fail Missing"
		            }
                }
            }

        }
    #List the untested Elements changed to unexpected for AppServices
    ForEach ($Object in $NetBackupServicesSource ) {
        If (!($NetBackupServicesTest.Property -Match $object.Name)) {
            $NetBackupServicesTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "NetBackupService"
			    Property = $($Object.Name)
		        Value = "State: ($($Object.State))<br/>Startup: $($Object.Startup)<br/>RunAs: $($Object.RunAs)"
	            Status = "Fail Unexpected"
			    }
            }

    }

    If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
    #Write-Host "Post App Services Environment: $Environment"
    #End NetBackup Services

###################################################

    #App Services Info
    Write-Host "App Services Tests"
    $AppServicesTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}

    #31/03/16 & 06/06/16 (MH) - Hack added to cope with new naming structure
    $PreviousEnvironment = $Environment
    Switch ($Environment.Length) {
        {$_ -eq 7} {$Environment = $Environment.SubString(3,4)}
        {$_ -eq 9} {$Environment = $Environment.SubString(5,4)}
        #{$_ -eq 7 -and $Environment -match "GP"} {$Environment = $Server.SubString(2).Replace("-","_")}
        default {$Environment = $Environment}
        }
    #23/01/22 (MH) - Hack for new environment name used in 2019 os
    If ( $os = "2019" ) { $Environment = $Environment.Replace("-1","") }

    Write-Host "App Environment: $Environment"

    ForEach ($Item in ($AppServicesInfoComp | ? {$_.Site -eq $Site -or $_.Site -eq "All"}) ) {
        $Found=$False
        $FailStatus=$Null
        $Passed=$Null
        $Failed=$Null
        $MissingValue=$Null
        #Serivce Correct
        IF ($AppServicesSource | ? { $_.Name -match $Item.Name -and $_.State -match $Item.State -and $_.Startup -match $Item.Startup -and $_.RunAs -match [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)  } ) {
            $Found=$True
            $passed=$AppServicesSource | ? { $_.Name -match $Item.Name -and $_.State -match $Item.State -and $_.Startup -match $Item.Startup -and $_.RunAs -match [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)}
            $Passed | % { $AppServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "AppService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($_.RunAs)"
	                Status = "Pass"
		            }
                }
            }

        #Serivce IncorrectCorrect
        IF ($AppServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) } ) {
            $Found=$True
            $Failed=$AppServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) }
            #$AppServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) } #| % {Write-Warning "Failed: Service -- $($_.Name)"}
            $FailureReason=$AppServicesSource | ? { $_.Name -match $Item.Name -and ($_.State -notmatch $Item.State -or $_.Startup -notmatch $Item.Startup -or $_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain) ) }
            Switch ($FailureReason) {
                {$_.State -notmatch $Item.State} {
                    $FailStatus="State<br>"
                    }
                {$_.Startup -notmatch $Item.Startup} {
                    $FailStatus=$FailStatus+"Startup<br>"
                    }
                #23/01/22 (MH) - Hack for new environment name used in 2019 os
                #{$_.RunAs -notmatch [Regex]::Escape($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain)} {
                {$_.RunAs -notmatch $(($Item.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))} {
                    $FailStatus=$FailStatus+"Account<br>"
                    }
                }

            $Failed | % { $AppServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "AppService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($_.RunAs)"
	                Status = "Fail:<br/>$FailStatus"
		            }
                }
            }

        #MissingValues mop up in case of unknowns
        If (!($Found)) {
            $MissingValue=$Item | select Name, State, Startup, Runas
            $MissingValue | % { $AppServicesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "AppService"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>Startup: $($_.Startup)<br/>RunAs: $($($_.RunAs).Replace('XXENVIRONMENTXX',$Environment).Replace('XXDOMAINXX',$Domain))"
	                Status = "Fail Missing"
		            }
                }
            }

        }
    #List the untested Elements changed to unexpected for AppServices
    ForEach ($Object in $AppServicesSource ) {
        IF (!($AppServicesTest.Property -Match $object.Name)) {
            $AppServicesTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "AppService"
			    Property = $($Object.Name)
		        Value = "State: ($($Object.State))<br/>Startup: $($Object.Startup)<br/>RunAs: $($Object.RunAs)"
	            Status = "Fail Unexpected"
			    }
            }

    }

    If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
    #Write-Host "Post App Services Environment: $Environment"
    #End App Services

###################################################

    #AppFiles Info Tests
    Write-Host "App File Tests"
    $AppFileInfoTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()
    $i=0

    If ($AppFilesSource -ne $Null) {
        ForEach ($Item in $AppFilesInfoComp) {
            $Found=$False
            $Passed=$Null
            $Failed=$Null
            $MissingValue=$Null

            $AppFilesSource | ? {$_.Name -match [Regex]::Escape($Item.'#text') -and $_.'#text' -match [Regex]::Escape($Item.'#text')}

            #App Correct
            IF ($AppFilesSource | ? {$_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -match $Item.'#text'}) {
                $Found=$True
                $passed=$AppFilesSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -match $Item.'#text'}
                $Passed | % { $AppFileInfoTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "AppFiles"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Pass"
		                }
                    }
                }
            #App Incorrect
            IF ($AppFilesSource | ? {$_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -notmatch $Item.'#text'}) {
                $Found=$True
                $Failed=$AppFilesSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -notmatch $Item.'#text'}
                $Failed | % { $AppFileInfoTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "AppFiles"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Fail: InCorrect Value"
		                }
                    }
                }

            #MissingValues mop up in case of unknowns
            If ($Found -ne $True) {
                $MissingValue=$Item
                $MissingValue | % { $AppFileInfoTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "AppFiles"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Fail Missing"
		                }
                    }
                }

            }

        #List the untested Elements changed to unexpected for Mobile Connection Tests
        ForEach ($Object in $AppFilesSource ) {
            IF (!($AppFileInfoTest.Property -Match [Regex]::Escape($($object.Name)))) {
                Write-Warning "$($Object.name) unexpected....  $($Object.'#text')"
                $AppFileInfoTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "AppFiles"
			        Property = $($Object.Name)
		            Value = "$($Object.'#text')"
	                Status = "Fail Unexpected"
			        }
                }
            }
        }
    #End App File Tests


####################################

    #Network Connection Tests
    Write-Host "Network Connection Tests"
    $NetConnectionsTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    ForEach ($Item in $NetTestInfoComp) {
        $Found=$False
        #$FailStatus=$Null
        $Passed=$Null
        $Failed=$Null
        $MissingValue=$Null

        #Connection Correct
        IF ($NetTestSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.State -match $Item.State }) {
            $Found=$True
            $passed=$NetTestSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.State -match $Item.State }
            $Passed | % { $NetConnectionsTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "NetConnection"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>IP: ($($_.IPAddress))"
	                Status = "Pass"
		            }
                }
            }

        #Connection Incorrect
        IF ($NetTestSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.State -notmatch $Item.State }) {
            $Found=$True
            $Failed=$NetTestSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.State -notmatch $Item.State }
            $Failed | % { $NetConnectionsTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "NetConnection"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>IP: ($($_.IPAddress))"
	                Status = "Fail: No Connection"
		            }
                }
            }

        #MissingValues mop up in case of unknowns
        If (!($Found)) {
            $MissingValue=$Item
            $MissingValue | % { $NetConnectionsTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "NetConnection"
		            Property = $($_.Name)
		            Value = "State: ($($_.State))<br/>IP: ($($_.IPAddress))"
	                Status = "Fail Missing"
		            }
                }
            }

        }
    #List the untested Elements changed to unexpected for NetConnection Tests
    ForEach ($Object in $NetTestSource ) {
        IF (!($NetConnectionsTest.Property -Match [Regex]::Escape($($object.Name)))) {
            $NetConnectionsTest += New-Object -TypeName PSObject  -Property @{
                Server = $Server
                Test = "NetConnection"
			    Property = $($Object.Name)
		        Value = "State: ($($Object.State))<br/>IP: ($($Object.IPAddress))"
	            Status = "Fail Unexpected"
			    }
            }
        }

    #End Network Connection Tests

#######################

    #Mobile Connection Tests
    Write-Host "Mobile Connection Tests"
    $MobileConnectionsTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If ($MobileTestSource -ne $Null) {
        ForEach ($Item in $MobileTestInfoComp) {
            $Found=$False
            $Passed=$Null
            $Failed=$Null
            $MissingValue=$Null

            #Mobile Correct
            IF ($MobileTestSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.State -match $Item.State }) {
                $Found=$True
                $passed=$MobileTestSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.State -match $Item.State }
                $Passed | % { $MobileConnectionsTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "Mobile"
		                Property = $($_.Name)
		                Value = "State: ($($_.State))</br>Environment: ($($_.Environment))"
	                    Status = "Pass"
		                }
                    }
                }

            #Mobile Incorrect
            IF ($MobileTestSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.State -notmatch $Item.State }) {
                $Found=$True
                $Failed=$MobileTestSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.State -notmatch $Item.State }
                $Failed | % { $MobileConnectionsTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "Mobile"
		                Property = $($_.Name)
		                Value = "State: ($($_.State))</br>Environment: ($($_.Environment))"
	                    Status = "Fail: No Connection"
		                }
                    }
                }

            #MissingValues mop up in case of unknowns
            If (!($Found)) {
                $MissingValue=$Item
                $MissingValue | % { $MobileConnectionsTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "Mobile"
		                Property = $($_.Name)
		                Value = "State: ($($_.State))</br>Environment: ($($_.Environment))"
	                    Status = "Fail Missing"
		                }
                    }
                }

            }
        #List the untested Elements changed to unexpected for Mobile Connection Tests
        ForEach ($Object in $MobileTestSource ) {
            IF (!($MobileConnectionsTest.Property -Match [Regex]::Escape($($object.Name)))) {
                $MobileConnectionsTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "Mobile"
			        Property = $($Object.Name)
		            Value = "State: ($($Object.State))</br>Environment: ($($Object.Environment))"
	                Status = "Fail Unexpected"
			        }
                }
            }
        }
    #End Mobile Connection Tests

###################################################
    #Program Info Tests
    Write-Host "Program Info Tests"
    $ProgramInfoTest=@()
    $Passed=@()
    $Failed=@()
    $WrongValue=@()
    $MissingValue=@()

    If ($ProgramInfoSource -ne $Null -Or $ProgramInfoSource -eq $Null) {
    #If ($ProgramInfoSource) {
        ForEach ($Item in $ProgramInfoComp) {
            $Found=$False
            $Passed=$Null
            $Failed=$Null
            $MissingValue=$Null

            #Program Correct
            If ($ProgramInfoSource | ? {$_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -match [Regex]::Escape($Item.'#text')}) {
                $Found=$True
                $passed=$ProgramInfoSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -match [Regex]::Escape($Item.'#text')}
                $Passed | % { $ProgramInfoTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "Programs"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Pass"
		                }
                    }
                }
            #Program IncorrectCorrect
            If ($ProgramInfoSource | ? {$_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -notmatch [Regex]::Escape($Item.'#text')}) {
                $Found=$True
                $Failed=$ProgramInfoSource | ? { $_.Name -match [Regex]::Escape($Item.Name) -and $_.'#text' -notmatch [Regex]::Escape($Item.'#text')}
                $Failed | % { $ProgramInfoTest += New-Object -TypeName PSObject -Property @{
                        Server = $Server
                        Test = "Programs"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Fail: InCorrect Value"
		                }
                    }
                }

            #MissingValues mop up in case of unknowns
            If (!($Found)) {
                $MissingValue=$Item
                $MissingValue | % { $ProgramInfoTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "Programs"
		                Property = $($_.Name)
		                Value = "$($_.'#text')"
	                    Status = "Fail Missing"
		                }
                    }
                }

            }
        #List the untested Elements changed to unexpected for Mobile Connection Tests
        ForEach ($Object in $ProgramInfoSource ) {
            IF (!($ProgramInfoTest.Property -Match [Regex]::Escape($($object.Name)))) {
                $ProgramInfoTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "Programs"
			        Property = $($Object.Name)
		            Value = "$($Object.'#text')"
	                Status = "Fail Unexpected"
			        }
                }
            }
        }
    #End Program Info Tests

######################################################################################

    If ($CertificateTestSource -ne $Null) {
        #Certificates Info
        Write-Host "Certificates Tests"
        $CertificatesTest=@()
        $Passed=@()
        $Failed=@()
        $WrongValue=@()
        $MissingValue=@()


        If (Test-Path -Path Variable:\PreviousEnvironment) {Remove-Variable PreviousEnvironment}
        $PreviousEnvironment = $Environment

        Switch ($Environment) {
            {$_ -match "GP" -and $Domain -eq "GPLive"} {$Environment=$Environment.SubString($Environment.length-2)}
            default {$Environment = $Environment}
            }

        #23/01/22 (MH) - Hack for new environment name used in 2019 os
        #If ( $os = "2019" ) { $Environment = $Environment.Replace("-1",""); $Environment = $Environment.SubString($Environment.length-2) }
        If ( $os = "2019" ) { $Environment = $Environment}

        ForEach ($Item in $CertificateTestInfoComp ) {
            $Found=$False
            $FailStatus=$Null
            $Passed=$Null
            $Failed=$Null
            $MissingValue=$Null

            #Certificate Correct
            If (($CertificateTestSource | ? { $_.Name -match $Item.Name.Replace('XXENVIRONMENTXX',$Environment) -and $_.Issuer -match $Item.Issuer -and $_.EndDate -match $Item.EndDate -and $_.Path -match $Item.Path}) -AND $Found -eq $False ) {
                $Found=$True
                $passed=$CertificateTestSource | ? { $_.Name -match $Item.Name.Replace('XXENVIRONMENTXX',$Environment) -and $_.Issuer -match $Item.Issuer -and $_.EndDate -match $Item.EndDate -and $_.Path -match $Item.Path }
                $Passed | % { $CertificatesTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "Certificates"
		                Property = $($_.Name)
		                Value = "Issuer: ($($_.Issuer))<br/>EndDate: $($_.EndDate)<br/>Path: $($_.Path)"
	                    Status = "Pass"
		                }
                    }
                }

            #Certificate IncorrectCorrect
            IF (($CertificateTestSource | ? { $_.Name -match $Item.Name.Replace('XXENVIRONMENTXX',$Environment) -and ($_.Issuer -notmatch $Item.Issuer -or $_.EndDate -notmatch $Item.EndDate) -and $_.Path -match $Item.Path}) -AND $Found -eq $False ) {
                $Found=$True
                $Failed=$CertificateTestSource | ? { $_.Name -match $Item.Name.Replace('XXENVIRONMENTXX',$Environment) -and ($_.Issuer -notmatch $Item.Issuer -or $_.EndDate -notmatch $Item.EndDate) -and $_.Path -match $Item.Path}
                $FailureReason=$CertificateTestSource | ? { $_.Name -match $Item.Name.Replace('XXENVIRONMENTXX',$Environment) -and ($_.Issuer -notmatch $Item.Issuer -or $_.EndDate -notmatch $Item.EndDate) -and $_.Path -match $Item.Path }
                Switch ($FailureReason) {
                    {$_.Issuer -notmatch $Item.Issuer} {
                        $FailStatus="Issuer<br>"
                        }
                    {$_.EndDate -notmatch $Item.EndDate} {
                        $FailStatus=$FailStatus+"EndDate<br>"
                        }
                    {$_.Path -notmatch $Item.Path} {
                        $FailStatus=$FailStatus+"Path<br>"
                        }
                    }

                $Failed | % { $CertificatesTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "Certificates"
		                Property = $($_.Name)
		                Value = "Issuer: ($($_.Issuer))<br/>EndDate: $($_.EndDate)<br/>Path: $($_.Path)"
	                    Status = "Fail:<br/>$FailStatus"
		                }
                    }
                }

            #MissingValues mop up in case of unknowns
            If (!($Found)) {
                $MissingValue=$Item | select Name, Issuer, EndDate, Path
                $MissingValue | % { $CertificatesTest += New-Object -TypeName PSObject  -Property @{
                        Server = $Server
                        Test = "Certificates"
		                Property = $($_.Name)
		                Value = "Issuer: ($($_.Issuer))<br/>EndDate: $($_.EndDate)<br/>Path: $($_.Path)"
	                    Status = "Fail Missing"
		                }
                    }
                }

            }
        #List the untested Elements check for unexpected Certificates
        $RefCertificatesTest=$Null
        $RefCertificatesTest=$CertificatesTest
        ForEach ($Object in $CertificateTestSource ) {
            IF (!($RefCertificatesTest.Property -Match [RegEx]::Escape($object.Name))) {
                $CertificatesTest += New-Object -TypeName PSObject  -Property @{
                    Server = $Server
                    Test = "Certificates"
			        Property = $($Object.Name)
		            Value = "Issuer: ($($Object.Issuer))<br/>EndDate: $($Object.EndDate)<br/>Path: $($Object.Path)"
	                Status = "Fail Unexpected"
			        }
                }
            }

        If (Test-Path -Path Variable:\PreviousEnvironment) {$Environment=$PreviousEnvironment}
        #End Certificates
    }

#############################################################################################


    #Collect all tests into pass or fails
    <#
    $FailedTests = @()
    $PassedTests = @()
    $Untested = @()
    #>

    $FailedTests += $osTest | ? {$_.Status -match "Fail"}
    $FailedTests += $DNSTest | ? {$_.Status -match "Fail"}
    $FailedTests += $DiskInfoTest | ? {$_.Status -match "Fail"}
    $FailedTests += $NetworkInfoTest | ? {$_.Status -match "Fail"}
    $FailedTests += $RouteInfoTest | ? {$_.Status -match "Fail"}
    $FailedTests += $HostFileInfoTest | ? {$_.Status -match "Fail"}
    $FailedTests += $DataDogTest | ? {$_.Status -match "Fail"}
    $FailedTests += $AntiVirusTest | ? {$_.Status -match "Fail"}
    $FailedTests += $MonitoringServicesTest | ? {$_.Status -match "Fail"}
    $FailedTests += $ProgramInfoTest | ? {$_.Status -match "Fail"}
    $FailedTests += $SQLInfoTest | ? {$_.Status -match "Fail"}
    $FailedTests += $SQLLoginTest | ? {$_.Status -match "Fail"}
    $FailedTests += $SQLAccessTest | ? {$_.Status -match "Fail"}
    $FailedTests += $SQLServiceSPNsTest | ? {$_.Status -match "Fail"}
    $FailedTests += $DBChecksTest | ? {$_.Status -match "Fail"}
    $FailedTests += $ClusterChecksTest | ? {$_.Status -match "Fail"}
    $FailedTests += $NetBackupServicesTest | ? {$_.Status -match "Fail"}
    $FailedTests += $AppServicesTest | ? {$_.Status -match "Fail"}
    $FailedTests += $AppFileInfoTest | ? {$_.Status -match "Fail"}
    $FailedTests += $NetConnectionsTest | ? {$_.Status -match "Fail"}
    $FailedTests += $MobileConnectionsTest | ? {$_.Status -match "Fail"}
    $FailedTests += $CertificatesTest | ? {$_.Status -match "Fail"}

    $PassedTests += $osTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $DNSTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $DiskInfoTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $NetworkInfoTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $RouteInfoTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $HostFileInfoTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $DataDogTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $AntiVirusTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $MonitoringServicesTest | ? {$_.Status -match "Pass"}
    $PassedTests += $ProgramInfoTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $SQLInfoTest | ? {$_.Status -match "Pass"}
    $PassedTests += $SQLLoginTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $SQLAccessTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $SQLServiceSPNsTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $DBChecksTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $ClusterChecksTest | ? {$_.Status -match "Pass"}
    $PassedTests += $NetBackupServicesTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $AppServicesTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $AppFileInfoTest | ? {$_.Status -match "Pass"}
    $PassedTests += $NetConnectionsTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $MobileConnectionsTest | ? {$_.Status -eq "Pass"}
    $PassedTests += $CertificatesTest | ? {$_.Status -eq "Pass"}

    $Untested += $osTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $DNSTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $DiskInfoTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $NetworkInfoTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $RouteInfoTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $HostFileInfoTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $DataDogTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $AntiVirusTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $MonitoringServicesTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $ProgramInfoTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $SQLInfoTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $SQLLoginTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $SQLAccessTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $SQLServiceSPNsTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $DBChecksTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $ClusterChecksTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $NetBackupServicesTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $AppServicesTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $AppFileInfoTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $NetConnectionsTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $MobileConnectionsTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}
    $Untested += $CertificatesTest | ? {$_.Status -ne "Pass" -and $_.Status -notmatch "Fail"}

    <#
    $richTextBox_Status.Text += "INFO: Compliance Check on $HostName Complete`n"
	$richTextBox_Status.Select()
	$richTextBox_Status.SelectionStart = $richTextBox_Status.Text.Length
	$richTextBox_Status.ScrollToCaret()
	$richTextBox_Status.Refresh()
    #>
#    }

    ###########OutPuts###############

    Write-Host "begin outputs"

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
    font-size:14px;
  }
  td.alt {
    text-align: right;
    padding: 2px;
    border: 2px solid #dcdcdc;
    background: #e3f0f7;
    font-size:14px;
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

  <title>$((gwmi Win32_ComputerSystem).Name) Compliance</title>
 </head>
 <body>
  <div id="header">
   <!--<h1>$((gwmi Win32_ComputerSystem).Name) Compliance Report</h1>-->
   <h1>$((gwmi Win32_ComputerSystem).Name) Compliance Report</h1>
   <h2>Report Generated : $strDate</h2>
   <!--<h2>Server : $((gwmi Win32_ComputerSystem).Name).$Domain</h2>-->
  </div>
  <div id="main">
   <HR WIDTH=90% COLOR=#336699 SIZE=10 Align=center>



"@


#Output O/S Info  class="center" width=100%
$Output += @"
   <h3 style="text-align:center">Failed Checks</h3>
   <table width=90% align=center>
   <TH>Test<TH>Server<TH>Status<TH>Property<TH>Value</TH></TH></TH></TH></TH>

"@

$RowCount = 0
Foreach ($Result in $FailedTests) {
    $Area = $Result.Test
	$Property = $Result.Property
	$value = $Result.Value
    $Status = $Result.Status
	$Server=$Result.Server
    switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
    Switch ($Status) {
        {$_ -match "Pass"} {$Color="color:Green"}
        {$_ -match "Fail"} {$Color="color:Red"}
        Default {$Color="color:Black"}
        }
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left" style=$color>$Area</td>
    <td style="text-align:left" style=$color>$Server</td>
    <td style="text-align:left" style=$color>$Status</td>
    <td style="text-align:left" style=$color>$Property</td>
    <td style=$color>$Value</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left" style=$color>$Area</td>
    <td class="alt" style="text-align:left" style=$color>$Server</td>
    <td class="alt" style="text-align:left" style=$color>$Status</td>
    <td class="alt" style="text-align:left" style=$color>$Property</td>
    <td class="alt" style=$color>$Value</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@

#Output O/S Info  class="center" width=100%
$Output += @"
   <h3 style="text-align:center">Passed Checks</h3>
   <table width=90% align=center>
   <TH>Test<TH>Server<TH>Status<TH>Property<TH>Value</TH></TH></TH></TH></TH>

"@

$RowCount = 0
Foreach ($Result in $PassedTests) {
    $Area = $Result.Test
	$Property = $Result.Property
	$value = $Result.Value
    $Status = $Result.Status
    $Server=$Result.Server
	switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
    Switch ($Status) {
        {$_ -match "Pass"} {$Color="color:Green"}
        {$_ -match "Fail"} {$Color="color:Red"}
        Default {$Color="color:Black"}
        }
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left" style=$color>$Area</td>
    <td style="text-align:left" style=$color>$Server</td>
    <td style="text-align:left" style=$color>$Status</td>
    <td style="text-align:left" style=$color>$Property</td>
    <td style=$color>$Value</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left" style=$color>$Area</td>
    <td class="alt" style="text-align:left" style=$color>$Server</td>
    <td class="alt" style="text-align:left" style=$color>$Status</td>
    <td class="alt" style="text-align:left" style=$color>$Property</td>
    <td class="alt" style=$color>$Value</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@

#Output O/S Info  class="center" width=100%
$Output += @"
   <h3 style="text-align:center">Untested</h3>
   <table width=90% align=center>
   <TH>Test<TH>Server<TH>Status<TH>Property<TH>Value</TH></TH></TH></TH></TH>

"@

$RowCount = 0
Foreach ($Result in $Untested) {
    $Area = $Result.Test
	$Property = $Result.Property
	$value = $Result.Value
    $Status = $Result.Status
	$Server=$Result.Server
    switch ($RowCount) {
	  		{ $_ % 2 -eq 1 } {$Row = "Odd" }
	  		{ $_ % 2 -eq 0 } {$Row = "Even" }
		}
    Switch ($Status) {
        {$_ -match "Pass"} {$Color="color:Green"}
        {$_ -match "Fail"} {$Color="color:Red"}
        Default {$Color="color:Black"}
        }
	If ($Row -eq "Even") {
		$Output += @"
    <tr>
    <td style="text-align:left" style=$color>$Area</td>
    <td style="text-align:left" style=$color>$Server</td>
    <td style="text-align:left" style=$color>$Status</td>
    <td style="text-align:left" style=$color>$Property</td>
    <td style=$color>$Value</td>
    </tr>

"@
		}
	else {
	   $Output += @"
    <tr>
    <td class="alt" style="text-align:left" style=$color>$Area</td>
    <td class="alt" style="text-align:left" style=$color>$Server</td>
    <td class="alt" style="text-align:left" style=$color>$Status</td>
    <td class="alt" style="text-align:left" style=$color>$Property</td>
    <td class="alt" style=$color>$Value</td>
    </tr>


"@
		}
	$RowCount++
}

$Output += @"
   </table>


"@

    #test whether C:\Emis path exists

    #IF (-not (Test-Path "C:\Emis\Host-Report\ComplianceCheck")) { New-Item -Path "C:\Emis\Host-Report\ComplianceCheck" -ItemType Directory}

    #10/01/2023 MH : a little housekeeping
    Write-Host "$((gwmi win32_ComputerSystem).Name) - Compliance Complete"
    Write-Host "Results ouput to $($ScriptPath)\Result\$((gwmi win32_ComputerSystem).Name).Compliance-Report.html"

    <#
    $richTextBox_Status.Text += "INFO: Compliance Check on $PD Complete`n"
	$richTextBox_Status.Text += "Results ouput to $Path\$PD.Compliance-Report.html`n
"
	$richTextBox_Status.Select()
	$richTextBox_Status.SelectionStart = $richTextBox_Status.Text.Length
	$richTextBox_Status.ScrollToCaret()
	$richTextBox_Status.Refresh()
    #>
    #Out-File -Filepath "C:\EMIS\Host-Report\ComplianceCheck\$Server.Compliance-Report.html" -InputObject $Output


    #Out-File -Filepath "$Path\$Server.Compliance-Report.html" -InputObject $Output

    #Out-File -Filepath "$Path\$PD.Compliance-Report.html" -InputObject $Output

    Out-File -Filepath "$($ScriptPath)\Result\$((gwmi win32_ComputerSystem).Name).Compliance-Report.html" -InputObject $Output



######    }

    }

$ScriptPath = "$(split-path($myinvocation.mycommand.path))"
#$Source = "$($ScriptPath)\Source"


#Call the Function
RunCompliance
