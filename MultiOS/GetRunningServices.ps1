<#
.SYNOPSIS
Detects the operating system (Windows, Linux, macOS) and lists running services/daemons.

.DESCRIPTION
This script uses PowerShell's built-in variables ($IsWindows, $IsLinux, $IsMacOS)
to determine the current OS. It then executes the platform-specific command
to retrieve a list of currently running services or daemons.
Requires PowerShell Core (v6+) on Linux and macOS.

.NOTES
Date:   2025-04-02
Linux:  Primarily targets systemd. Includes a basic fallback for SysVinit/init.d ('service').
        The 'service' command output varies and might require sudo.
macOS:  Filters 'launchctl list' output to show only processes with a running PID.

.EXAMPLE
./Get-RunningServicesCrossPlatform.ps1
#>

# Announce the start and OS detection
Write-Host "--------------------------------------------------"
Write-Host "Attempting to detect Operating System and list running services..."
Write-Host "Current Time: $(Get-Date)"
Write-Host "--------------------------------------------------"
Write-Host ""

# Check for Windows
if ($IsWindows) {
    Write-Host "[OS Detected: Windows]"
    Write-Host "Listing running services using 'Get-Service'..."
    Write-Host "--- Running Windows Services ---"
    try {
        # Get services where the status is 'Running' and select relevant properties
        Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object Status, Name, DisplayName | Out-Host
    } catch {
        Write-Error "Failed to retrieve Windows services. Error: $($_.Exception.Message)"
    }
    Write-Host "--------------------------------"

# Check for Linux
} elseif ($IsLinux) {
    Write-Host "[OS Detected: Linux]"

    # Prefer systemd (systemctl) as it's most common on modern systems
    $systemctlPath = Get-Command systemctl -ErrorAction SilentlyContinue
    if ($systemctlPath) {
        Write-Host "Using systemd (systemctl) to list running services..."
        Write-Host "Command: systemctl list-units --type=service --state=running --no-pager"
        Write-Host "--- Running systemd Services (Linux) ---"
        try {
            # Execute systemctl command to list running service units
            # --no-pager prevents hanging if output is long
            systemctl list-units --type=service --state=running --no-pager
        } catch {
             Write-Error "Failed to execute systemctl. Error: $($_.Exception.Message)"
        }
        Write-Host "--------------------------------------"
    } else {
        # Fallback for systems without systemd (potentially SysVinit)
        Write-Warning "systemctl command not found. Attempting fallback using 'service --status-all'."
        Write-Warning "Note: Output format varies and may not show *only* running services. May require 'sudo'."
        Write-Host "Command: service --status-all"
        Write-Host "--- Service Status (Linux - Fallback) ---"
        try {
             # Execute service command. This might require elevated privileges.
             service --status-all
        } catch {
            Write-Error "Failed to run 'service --status-all'. It might require elevated privileges (sudo) or may not be available/supported on this distribution."
            Write-Error "Error details: $($_.Exception.Message)"
        }
        Write-Host "-----------------------------------------"
    }

# Check for macOS
} elseif ($IsMacOS) {
    Write-Host "[OS Detected: macOS]"
    Write-Host "Using launchd (launchctl) to list running jobs..."
    # Explain that we filter for PIDs
    Write-Host "Filtering 'launchctl list' for entries with a PID (indicates running state)."
    Write-Host "Command: launchctl list | Select-String -Pattern '^[0-9]+\s+'"
    Write-Host "--- Running launchd Jobs (macOS) ---"
    try {
        # Execute launchctl list and pipe to Select-String to filter lines starting with a number (PID)
        launchctl list | Select-String -Pattern '^[0-9]+\s+'
    } catch {
        Write-Error "Failed to execute launchctl or filter its output. Error: $($_.Exception.Message)"
    }
    Write-Host "------------------------------------"

# Handle unsupported OS
} else {
    Write-Error "[OS Detection Failed]"
    Write-Error "Could not determine a supported Operating System (Windows, Linux, macOS)."
    Write-Host "Automatic Variables State:"
    Write-Host "IsWindows: $IsWindows"
    Write-Host "IsLinux:   $IsLinux"
    Write-Host "IsMacOS:   $IsMacOS"
    # You could add $PSVersionTable.OS here for more debug info if needed
    # Write-Host "PSVersionTable.OS: $($PSVersionTable.OS)"
}

Write-Host ""
Write-Host "--------------------------------------------------"
Write-Host "Script finished."
Write-Host "--------------------------------------------------"