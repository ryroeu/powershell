#Requires -Version 5.1 # Minimum for Windows PowerShell, Core is implicitly higher

<#
.SYNOPSIS
Checks the last reboot time of the local computer and determines if a reboot is needed (older than 30 days).

.DESCRIPTION
This script auto-detects the operating system (Windows, macOS, Linux).
It retrieves the computer name and the last time the system was booted.
It calculates the duration since the last boot.
If the duration is greater than 30 days, it prints "[ComputerName]: Reboot Required".
Otherwise, it prints "[ComputerName]: Reboot Not Required".
Requires PowerShell Core (pwsh) on macOS and Linux.

.NOTES
Date:   2025-04-02
OS Requirements: Windows (PowerShell 5.1+), macOS (PowerShell Core), Linux (PowerShell Core)
Command Dependencies: uptime (Linux), sysctl (macOS)

.EXAMPLE
./Check-RebootNeeded.ps1

Computer Name       : MY-WINDOWS-PC
Operating System    : Windows
Last Reboot Time    : 2025-03-15 10:30:00 AM
Days Since Reboot   : 17.58
Status: Reboot Not Required

.EXAMPLE
./Check-RebootNeeded.ps1 # On a Linux machine booted 45 days ago

Computer Name       : my-linux-server
Operating System    : Linux
Last Reboot Time    : 2025-02-16 08:00:00 AM
Days Since Reboot   : 45.22
Status: Reboot Required
#>

# --- Configuration ---
$RebootThresholdDays = 30

# --- Script Body ---

# Initialize variables
$computerName = $env:COMPUTERNAME # Usually works across platforms in PS Core
$lastBootTime = $null
$osType = "Unknown"
$errorMessage = $null

# Determine OS and get Last Boot Time
if ($IsWindows) {
    $osType = "Windows"
    try {
        # CIM instance is reliable on Windows
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $lastBootTime = $osInfo.LastBootUpTime
        # Get computer name more reliably on Windows if $env:COMPUTERNAME is weird (e.g., truncated)
        $compSys = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $computerName = $compSys.Name
    } catch {
        $errorMessage = "Error retrieving WMI/CIM data on Windows: $($_.Exception.Message)"
    }
} elseif ($IsMacOS) {
    $osType = "macOS"
    try {
        # Get computer name using hostname command if needed (can sometimes be more reliable than env var)
        # $computerName = hostname
        # Use sysctl kern.boottime which gives epoch seconds
        $bootTimeOutput = sysctl kern.boottime -ErrorAction Stop
        if ($bootTimeOutput -match 'sec\s*=\s*(\d+)') {
            $epochSeconds = [long]$matches[1]
            # Convert Unix Epoch seconds (UTC) to local DateTime
            $lastBootTime = [datetimeoffset]::FromUnixTimeSeconds($epochSeconds).LocalDateTime
        } else {
            $errorMessage = "Could not parse boot time from 'sysctl kern.boottime' output: $bootTimeOutput"
        }
    } catch {
        $errorMessage = "Error running 'sysctl kern.boottime' on macOS: $($_.Exception.Message). Is the command available?"
    }
} elseif ($IsLinux) {
    $osType = "Linux"
    try {
        # Get computer name using hostname command if needed
        # $computerName = hostname
        # Use 'uptime -s' which gives YYYY-MM-DD HH:MM:SS format (usually)
        $bootTimeString = uptime -s -ErrorAction Stop
        # Attempt to parse the date string directly
        $lastBootTime = Get-Date $bootTimeString -ErrorAction Stop
    } catch {
        # Handle potential parsing errors or command not found
         $errorMessage = "Error running/parsing 'uptime -s' on Linux: $($_.Exception.Message). Is 'uptime' installed and in PATH?"
    }
} else {
    $errorMessage = "Unsupported operating system detected or PowerShell Core version is too old to determine OS."
}

# --- Reporting ---

Write-Host "Computer Name       : $computerName"
Write-Host "Operating System    : $osType"

if ($errorMessage) {
    Write-Error "Failed to determine last boot time. $errorMessage"
} elseif ($null -eq $lastBootTime) {
     Write-Error "Could not determine the last boot time for an unknown reason on $osType."
} else {
    # Calculate timespan since last boot
    $currentTime = Get-Date
    $timeSinceBoot = $currentTime - $lastBootTime
    $daysSinceBoot = $timeSinceBoot.TotalDays

    # Display details
    Write-Host "Last Reboot Time    : $lastBootTime"
    Write-Host "Days Since Reboot   : $($daysSinceBoot.ToString('F2'))" # Format to 2 decimal places

    # Check against threshold and print final status
    if ($daysSinceBoot -gt $RebootThresholdDays) {
        Write-Host "Status: Reboot Required" -ForegroundColor Yellow
    } else {
        Write-Host "Status: Reboot Not Required" -ForegroundColor Green
    }
}