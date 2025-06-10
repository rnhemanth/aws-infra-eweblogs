$taskName = "Move-Core-Resource"
$task = (Get-ScheduledTask -TaskName $taskName -erroraction 'silentlycontinue').TaskName

if ($task -eq $taskName) {
  Write-Output "Task already exists"
} else {
  schtasks.exe /Create /XML C:\EMIS\Clustask\MoveCoreResource\Tasks\Move-Core-Resources.xml /tn "\Microsoft\Windows\Failover Clustering\Move-Core-Resource"
  $XMLTask=Get-Content C:\EMIS\Clustask\MoveCoreResource\Tasks\Move-Core-Resources.xml | Out-String
}
