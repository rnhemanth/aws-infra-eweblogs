# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Disable IIS Logging
$dontLog = (get-WebConfigurationProperty -PSPath "IIS:\" -filter "system.webServer/httpLogging" -name dontLog).Value
Write-Output " IIS Do not Log was set to $dontLog" 
set-WebConfigurationProperty -PSPath "IIS:\" -filter "system.webServer/httpLogging" -name dontLog -value $true
$dontLog = (get-WebConfigurationProperty -PSPath "IIS:\" -filter "system.webServer/httpLogging" -name dontLog).Value
Write-Output " IIS Do not log is now set to $dontLog" 