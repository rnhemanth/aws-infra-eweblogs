Function fn_LogWrite {
    #Writes output to log file
    Param ([string]$logString)
	$Date = "{0:dd/MM/yyyy HH:mm:ss}" -f (get-date)
	$logString = "$Date $logString"
    Add-content $LogFile -value $logString
	}

####################################################

Function fn_LogError {
    param ( $ErrorVar )
    fn_LogWrite "Error Command: $($ErrorVar.InvocationInfo.PositionMessage)"
    fn_LogWrite "Error Message: $($ErrorVar.Exception.Message)"
    }

####################################################

#Set up the values for the log file
$TimeDate = "{0:MM-yyyy}" -f (get-date)
#Set the path from which script is running
$ScriptPath="$(split-path($myinvocation.mycommand.path))"
#Set the path for the log file
$LogPath="$(split-path($myinvocation.mycommand.path))\Logs"
#Return the local server name
$LocalServer=$((Get-WmiObject Win32_computerSystem).Name)
#Get the script name
$ScriptName=($myinvocation.MyCommand.Name).replace('.ps1','')
#Create log folder if one doesn't exist
If (-not (Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType Directory | out-Null }
#Set the Log File
$LogFile = "$($LogPath)\$($LocalServer)_$($ScriptName)_$($TimeDate).log"
#ScriptPath
$ScriptPath = "$(split-path($myinvocation.mycommand.path))"

$SQLAGs = @()
$SQLAGs += Get-ClusterResource | ? ResourceType -eq "SQL Server Availability Group"
$CoreRes = Get-ClusterGroup -Name "Cluster Group"

If ( $SQLAGs.Count -ge 1 ) {
    Write-Host "Comparing location/owner of Core Resources with 1st AG location/owner for Cluster $($CoreRes.Cluster.Name)"
    fn_LogWrite "Comparing location/owner of Core Resources with 1st AG location/owner for Cluster $($CoreRes.Cluster.Name)"
    If ( $CoreRes.OwnerNode -ne $SQLAGs[0].OwnerNode ) {
        Write-Host "Core Resources to be moved from $($CoreRes.OwnerNode) to $($SQLAGs[0].OwnerNode)"
        fn_LogWrite "Core Resources to be moved from $($CoreRes.OwnerNode) to $($SQLAGs[0].OwnerNode)"
        Try {
            $Result=Get-ClusterGroup -name $CoreRes.Name | Move-ClusterGroup -Node ($SQLAGs[0].OwnerNode).Name
            $Result | % {Write-Host "Name: $($_.Name) - OwnerNode: $($_.OwnerNode) - State: $($_.State)"}
            $Result | % {fn_LogWrite "Name: $($_.Name) - OwnerNode: $($_.OwnerNode) - State: $($_.State)"}
            Write-Host "Core Cluster Group moved successfully"
            fn_LogWrite "Core Cluster Group moved successfully"
            }
        Catch {
            Write-Host "ERROR Moving $($CoreResources.Name) from $($CoreResources.OwnerNode) to $($Resource.OwnerNode)"
            Write-Host "$Error[0]"
            fn_LogWrite "ERROR Moving $($CoreResources.Name) from $($CoreResources.OwnerNode) to $($Resource.OwnerNode)"
            fn_LogError $Error[0]
            }
        }
    Else {
        Write-Host "Core Cluster Resources are running on same node $($CoreRes.OwnerNode) as AG $($SQLAGs[0].Name)"
        fn_LogWrite "Core Cluster Resources are running on same node $($CoreRes.OwnerNode) as AG $($SQLAGs[0].Name)"
        }
    }
