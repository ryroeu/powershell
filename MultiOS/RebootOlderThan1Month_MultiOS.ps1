#Requires -RunAsAdministrator # On Windows, administrator privileges are needed for Restart-Computer/shutdown
<#
.SYNOPSIS
    Reboots older than 1 month across multiple operating systems.
#>

# On Linux/macOS, this script needs to be run with sudo for the shutdown command.

<#
.SYNOPSIS
Checks the system uptime and initiates a reboot if it exceeds one month.
Works on Windows, Linux, and macOS.

.DESCRIPTION
This script automatically detects the operating system it's running on.
It retrieves the timestamp of the last system boot.
It calculates the duration since the last boot (uptime).
If the uptime is greater than 30 days (approximating one month), it schedules
a system reboot to occur in 5 minutes.

Warning: This script forces a reboot. Ensure all work is saved on target machines.

Requires:
- Windows: PowerShell 5.1 or later. Run as Administrator.
- Linux: PowerShell Core (pwsh) 7+ installed. Run with sudo (sudo pwsh script.ps1).
- macOS: PowerShell Core (pwsh) 7+ installed. Run with sudo (sudo pwsh script.ps1).

.NOTES
Date:   2025-04-02
Version: 1.1

Definition of "one month": For simplicity and consistency, this script uses 30 days.

.EXAMPLE
# Run directly on any supported OS (ensure correct permissions/sudo)
./Check-UptimeAndReboot.ps1

.LINK
PowerShell Built-in Variables: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables
Restart-Computer Cmdlet: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/restart-computer
shutdown command (Linux/macOS): man shutdown
#>

# --- Configuration ---
$RebootThresholdDays = 30
$RebootDelayMinutes = 5
# Convert delay to seconds for Windows shutdown command if used
$RebootDelaySeconds = $RebootDelayMinutes * 60

# --- Script Body ---

Write-Host "-------------------------------------"
Write-Host "Checking System Uptime..."
Write-Host "Current Time: $(Get-Date)"
Write-Host "-------------------------------------"

# Initialize variables
$lastBootTime = $null

# --- OS Detection and Last Boot Time Retrieval ---
try {
    if ($IsWindows) {
        Write-Host "Detected Operating System: Windows"
        # Get last boot time using CIM (more modern than WMI)
        $lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        if (-not $lastBootTime) {
            throw "Failed to retrieve LastBootUpTime from WMI/CIM."
        }
        Write-Host "Last Boot Time (Windows): $lastBootTime"

    } elseif ($IsLinux) {
        Write-Host "Detected Operating System: Linux"
        # Get last boot time using 'uptime -s' command
        # The output format is usually 'YYYY-MM-DD HH:MM:SS'
        $bootTimeString = (uptime -s).Trim()
        if ($LASTEXITCODE -ne 0 -or -not $bootTimeString) {
             throw "Failed to execute 'uptime -s' or received empty output."
        }
         # Attempt to parse the date string directly
        try {
            $lastBootTime = Get-Date -Date $bootTimeString -ErrorAction Stop
            Write-Host "Last Boot Time (Linux): $lastBootTime (Parsed from '$bootTimeString')"
        } catch {
             throw "Failed to parse the boot time string '$bootTimeString' from 'uptime -s'. Error: $($_.Exception.Message)"
        }


    } elseif ($IsMacOS) {
        Write-Host "Detected Operating System: macOS"
        # Get last boot time using 'sysctl -n kern.boottime'
        # Output format like: { sec = 1678886400, usec = 0 } Mon Mar 15 10:00:00 2023
        # We need the epoch seconds (the 'sec' value).
        $bootInfo = (sysctl -n kern.boottime).Trim()
         if ($LASTEXITCODE -ne 0 -or -not $bootInfo) {
             throw "Failed to execute 'sysctl -n kern.boottime' or received empty output."
        }
        # Extract the epoch seconds using regex
        if ($bootInfo -match 'sec\s*=\s*(\d+)') {
            $epochSeconds = $Matches[1]
            # Convert epoch seconds to DateTime object
            # Using .NET methods for reliable conversion
            $utcBootTime = [System.DateTimeOffset]::FromUnixTimeSeconds([long]$epochSeconds).UtcDateTime
            $lastBootTime = $utcBootTime.ToLocalTime() # Convert to local time
             Write-Host "Last Boot Time (macOS): $lastBootTime (Converted from epoch $epochSeconds)"
        } else {
            throw "Failed to parse epoch seconds from sysctl output: '$bootInfo'"
        }

    } else {
        Write-Error "Unsupported Operating System detected."
        # Exit cleanly if OS is not supported
        Exit 1
    }
} catch {
    Write-Error "Error retrieving last boot time: $($_.Exception.Message)"
    Write-Error "Script cannot continue without the last boot time."
    Exit 1 # Exit the script if boot time couldn't be determined
}

# --- Uptime Calculation and Check ---
if ($lastBootTime) {
    $currentTime = Get-Date
    $uptimeDuration = $currentTime - $lastBootTime
    $rebootThreshold = New-TimeSpan -Days $RebootThresholdDays

    Write-Host "System Uptime: $($uptimeDuration.Days) days, $($uptimeDuration.Hours) hours, $($uptimeDuration.Minutes) minutes"
    Write-Host "Reboot Threshold: $RebootThresholdDays days"

    if ($uptimeDuration -gt $rebootThreshold) {
        Write-Warning ("Uptime ($(($uptimeDuration).ToString('g'))) exceeds the threshold of $RebootThresholdDays days.")
        Write-Host "Initiating system reboot in $RebootDelayMinutes minutes..."

        # --- Platform-Specific Reboot Command ---
        try {
            if ($IsWindows) {
                Write-Host "Executing: shutdown /r /t $RebootDelaySeconds /f /c 'System reboot initiated by uptime policy script.'"
                # Using shutdown.exe for clearer messaging and standard behavior.
                # /r = reboot, /t = time in seconds, /f = force close apps, /c = comment
                shutdown /r /t $RebootDelaySeconds /f /c "System reboot initiated by uptime policy script."

                # Alternative using PowerShell cmdlet (delay is in seconds):
                # Restart-Computer -Delay $RebootDelaySeconds -Force -WhatIf # Remove -WhatIf to execute
            } elseif ($IsLinux) {
                Write-Host "Executing: sudo shutdown -r +$RebootDelayMinutes 'System rebooting in $RebootDelayMinutes minutes due to uptime policy.'"
                # Requires sudo privileges. + specifies delay in minutes.
                 sudo shutdown -r +$RebootDelayMinutes "System rebooting in $RebootDelayMinutes minutes due to uptime policy."
                 if ($LASTEXITCODE -ne 0) {
                    throw "shutdown command failed. Ensure script is run with sudo."
                 }
            } elseif ($IsMacOS) {
                Write-Host "Executing: sudo shutdown -r +$RebootDelayMinutes 'System rebooting in $RebootDelayMinutes minutes due to uptime policy.'"
                # Requires sudo privileges. + specifies delay in minutes.
                 sudo shutdown -r +$RebootDelayMinutes "System rebooting in $RebootDelayMinutes minutes due to uptime policy."
                 if ($LASTEXITCODE -ne 0) {
                    throw "shutdown command failed. Ensure script is run with sudo."
                 }
            }
            Write-Host "Reboot command issued successfully."

        } catch {
            Write-Error "Failed to initiate reboot: $($_.Exception.Message)"
            Write-Error "Please check permissions (Run as Administrator/sudo) and ensure shutdown command is available."
            Exit 1
        }

    } else {
        Write-Host "System uptime is within the acceptable threshold. No reboot required."
    }

} else {
    # This part should ideally not be reached due to the try/catch block above,
    # but added as a safeguard.
    Write-Error "Could not determine the last boot time. Cannot proceed with uptime check."
    Exit 1
}

Write-Host "-------------------------------------"
Write-Host "Script finished."
Write-Host "-------------------------------------"

# Exit with success code 0 if no errors forced an earlier exit
Exit 0