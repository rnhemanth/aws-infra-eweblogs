<powershell>
Set-TimeZone "GMT Standard Time"
Enable-WSManCredSSP -Role Client -DelegateComputer localhost -Force
New-Item C:\en-GB.xml -ItemType File
Set-Content C:\en-GB.xml '<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
<!--User List-->
<gs:UserList>
    <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/>
</gs:UserList>
<gs:UserLocale>
    <gs:Locale Name="en-GB" SetAsCurrent="true" ResetAllSettings="true"/>
</gs:UserLocale>
<!-- system locale -->
<gs:SystemLocale Name="en-GB"/>
<!--location-->
<gs:LocationPreferences>
    <gs:GeoID Value="242"/>
</gs:LocationPreferences>
<gs:InputPreferences>
    <!--en-GB-->
    <gs:InputLanguageID Action="add" ID="0809:00000809" Default="true"/>
    <!--remove-en-US-->
    <gs:InputLanguageID Action="remove" ID="0409:00000409"/>
</gs:InputPreferences>
</gs:GlobalizationServices>
'
$Process = Start-Process -FilePath Control.exe -ArgumentList "intl.cpl,,/f:""C:\\en-GB.xml""" -NoNewWindow -PassThru -Wait
$Process.ExitCode
Remove-Item 'C:\en-GB.xml'
Enable-WSManCredSSP -Role Client -DelegateComputer localhost -Force

Start-Sleep -Seconds 120
Get-Disk | Where-Object IsSystem -eq $False | ForEach-Object {
  if ($_.PartitionStyle -eq 'RAW') {
    Initialize-Disk -Number $_.Number -PartitionStyle GPT
    Set-Disk -Number $_.Number -IsOffline $False
    $VolumeId=$_.SerialNumber -replace "_[^ ]*$" -replace "vol", "vol-"
    $InstanceId = Get-EC2InstanceMetadata -Path '/instance-id'
    $DriveLetter = Get-EC2Volume -Filter @{Name="volume-id";Values=$VolumeId},@{Name="attachment.instance-id";Values=$instanceId}  |ForEach-Object {$_.Tags}|where Key -eq "DriveLetter"|Select-Object -Property Value |foreach-Object {$_.Value}
    $DriveName = Get-EC2Volume -Filter @{Name="volume-id";Values=$VolumeId},@{Name="attachment.instance-id";Values=$instanceId}  |ForEach-Object {$_.Tags}|where Key -eq "DriveName"|Select-Object -Property Value |foreach-Object {$_.Value}
    if ($DriveLetter -eq $null) {
      Write-Output "DriveLetter tag not found for volume $VolumeId. Skipping volume mount."
    }
    if ($DriveName -eq $null) {
      Write-Output "DriveName tag not found for volume $VolumeId. Skipping volume mount."
    }
    New-Partition -DiskNumber $_.Number -DriveLetter $DriveLetter -UseMaximumSize
    Format-Volume -DriveLetter $DriveLetter -FileSystem NTFS -NewFileSystemLabel $DriveName -AllocationUnitSize 65536
  } else {
    $VolumeId = $_.SerialNumber -replace "_[^ ]*$" -replace "vol", "vol-"
    $InstanceId = Get-EC2InstanceMetadata -Path '/instance-id'
    $DriveLetter = Get-EC2Volume -Filter @{Name="volume-id";Values=$VolumeId},@{Name="attachment.instance-id";Values=$instanceId} | ForEach-Object {$_.Tags} | Where-Object Key -eq "DriveLetter" | Select-Object -Property Value | ForEach-Object {$_.Value}
    $DriveName = Get-EC2Volume -Filter @{Name="volume-id";Values=$VolumeId},@{Name="attachment.instance-id";Values=$instanceId} | ForEach-Object {$_.Tags} | Where-Object Key -eq "DriveName" | Select-Object -Property Value | ForEach-Object {$_.Value}
    if ($DriveLetter -eq $null) {
      Write-Output "DriveLetter tag not found for volume $VolumeId. Skipping volume mount."
    }
    if ($DriveName -eq $null) {
      Write-Output "DriveName tag not found for volume $VolumeId. Skipping volume mount."
    }
    $existingPartition = (Get-Partition -DiskNumber $_.Number).Type | Select-String -NotMatch "Reserved"
    $mountedVolume = Get-Partition -DiskNumber $_.Number | Where-Object {$_.DriveLetter -eq $DriveLetter}
    if ($mountedVolume -ne $null) {
      Write-Output "Volume $VolumeId is already mounted with drive letter $DriveLetter."
    } elseif ($existingPartition -eq $null -or $existingPartition -eq '' ) {
      New-Partition -DiskNumber $_.Number -DriveLetter $DriveLetter -UseMaximumSize
      Format-Volume -DriveLetter $DriveLetter -FileSystem NTFS -NewFileSystemLabel $DriveName -AllocationUnitSize 65536
    } else {
      Write-Host "Disk $($_.Number) already has partitions. Skipping New-Partition and Format-Volume operations."
    }
  }
}

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" -Name "ProtectionPolicy" -PropertyType "DWORD" -Value "1"


# Update hostname
if ($(hostname) -ne '${hostname}') {
  Rename-Computer -NewName '${hostname}' -Force -Restart
}
Write-Output "hostname updated"

# Create Local Administrator
if (-not (Get-LocalUser emis-admin 2>$null)) {
    New-LocalUser -Name "emis-admin" -Description "Replaces Local Administrator. managed by LAPS" -NoPassword
    Add-LocalGroupMember -Group "Administrators" -Member "emis-admin"
}
else {
  Write-Output "emis-admin already exists"
}

# Join Domain
if ((Get-WmiObject win32_computersystem).partofdomain -eq $false)  {
  $FetchedSecret = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId ${DomainPassword}).SecretString
  $userName = $FetchedSecret.shortname+"\domain-joiner"
  $Credentials = (New-Object PSCredential($username,(ConvertTo-SecureString $FetchedSecret.password -AsPlainText -Force)))
  Add-Computer -DomainName $FetchedSecret.domain -OUPath "${OUPath}" -Credential $Credentials -force -Options JoinWithNewName,AccountCreate -restart
}
else {
$DomainOutput = (Get-WmiObject win32_computersystem).Domain
Write-Output "Part of Domain $DomainOutput"
}

### Add more DBS specific content here ###

## Update pagefile Settings
$ComputerSystem = Get-WmiObject -ClassName Win32_ComputerSystem
$ComputerSystem.AutomaticManagedPagefile = $false
$ComputerSystem.Put()

#Set Pagefile Size
$PageFileSetting = Get-WmiObject -ClassName Win32_PageFileSetting | Where-Object {$_.name -eq "C:\pagefile.sys"}
$PageFileSetting.InitialSize = 8192
$PageFileSetting.MaximumSize = 16384
try {
  $PageFileSetting.Put()
  Write-Output "Page file size set successfully."
  Write-Output $PageFileSetting
}
catch {
  Write-Output "Error occurred while trying to update page file settings: $_"
}

## DNS and PTR registration
$networkConfig = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'"
$networkConfig.SetDynamicDNSRegistration($true,$true)
ipconfig /registerdns

</powershell>
<persist>true</persist>