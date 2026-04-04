<#
.SYNOPSIS
Exports a selected Windows event log from each server in a list and moves the `.evtx` files to a central share.
#>

<# VARIABLES #>
# Specify which Log File
$EventLogName = "Application"
# Specify drive to store event logs (local path on remote machine)
$logDir = "C:\logs"
# Specify server to store exported logs
$dest = "SERVERNAME"
# Simple Server list
$servers = Get-Content C:\Servers.txt
<# END VARIABLES #>

# For loop to do the work
foreach ($server in $servers) {
    # Create target folder on remote host if it does not exist
    $TARGETROOT = "\\$server\c$\logs"
    if (!(Test-Path -Path $TARGETROOT)) {
        New-Item -ItemType Directory -Path $TARGETROOT | Out-Null
    }

    # Creating a file name based on server, log and time
    $exportFileName = $server + "_" + $EventLogName + "_" + (Get-Date -f yyyyMMdd) + ".evtx"

    # Use wevtutil via Invoke-Command to export the log on the remote machine
    Invoke-Command -ComputerName $server -ScriptBlock {
        param($logName, $logPath, $fileName)
        if (!(Test-Path -Path $logPath)) {
            New-Item -ItemType Directory -Path $logPath | Out-Null
        }
        & wevtutil.exe epl $logName "$logPath\$fileName" /ow:true
    } -ArgumentList $EventLogName, $logDir, $exportFileName

    # Create an export folder if it does not exist
    $target = "\\$dest\c$\logs\export"
    if (!(Test-Path -Path $target)) {
        New-Item -ItemType Directory -Path $target | Out-Null
    }

    # Move the exported log to the central collection share
    Move-Item "$TARGETROOT\$exportFileName" $target
}
