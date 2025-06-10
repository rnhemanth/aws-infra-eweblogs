[CmdletBinding()]
Param(
  $ssmsinstaller
)

# Check if the local file exists
if (Test-Path -Path $ssmsinstaller) {
    Write-Output "$ssmsinstaller file exists"
} else {
   Write-Output "$ssmsinstaller does not exist"
   exit
}

Write-Host "Installing SQL Server Management Studio..."
Start-Process -FilePath $ssmsinstaller -Args "/install /quiet" -Wait
Write-Host "Installation completed"
