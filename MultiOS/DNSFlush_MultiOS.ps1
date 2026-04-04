<#
.SYNOPSIS
Flushes the DNS cache on Windows, macOS, or Linux.

.DESCRIPTION
This script automatically detects the operating system it is running on
and executes the appropriate command to flush the local DNS resolver cache.
It uses automatic variables ($IsWindows, $IsMacOS, $IsLinux) on PowerShell 6+
and legacy checks for Windows PowerShell 5.1.
On macOS and Linux, it uses 'sudo' and may prompt for an administrator password.
On Windows, it's recommended to run this script from an elevated (Administrator) PowerShell prompt.

.NOTES
Date:   2025-04-02
Requires: PowerShell (Windows PowerShell 5.1 supported for Windows OS only; PowerShell 6+ recommended for cross-platform compatibility).
          Administrator/root privileges may be required.
#>

Write-Host "Starting DNS Flush Script..."
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host "PowerShell Edition: $($PSVersionTable.PSEdition)"
Write-Host "Platform: $($PSVersionTable.Platform)"
Write-Host "OS: $($PSVersionTable.OS)"
Write-Host "-------------------------------------"

# --- Function to Execute Windows DNS Flush ---
# Avoid repeating the code block
function Clear-WindowsDn {
    Write-Host "Executing: ipconfig /flushdns"
    try {
        # Execute and capture output/errors
        $result = ipconfig /flushdns
        Write-Host $result
        # Check the automatic variable $? for success of the last command
        if ($?) {
             Write-Host "Windows DNS cache successfully flushed." -ForegroundColor Green
        } else {
             # ipconfig usually outputs errors directly, but $? confirms failure
             Write-Warning "ipconfig /flushdns command reported an issue. Check output above."
             Write-Warning "Ensure you are running PowerShell as Administrator."
        }
    } catch {
        Write-Error "Failed to execute ipconfig /flushdns."
        Write-Error $_.Exception.Message
        Write-Error "Ensure you are running PowerShell as Administrator."
    }
}

# --- Main OS Detection and Execution Logic ---

# Check if running PowerShell 6 or newer
if ($PSVersionTable.PSVersion.Major -ge 6) {
    Write-Host "Using PowerShell 6+ automatic OS variables for detection."

    if ($IsWindows) {
        Write-Host "Operating System: Windows (detected via `$IsWindows)"
        Clear-WindowsDns

    } elseif ($IsMacOS) {
        Write-Host "Operating System: macOS (detected via `$IsMacOS)"
        Write-Host "Executing: sudo dscacheutil -flushcache"
        Write-Host "Executing: sudo killall -HUP mDNSResponder"
        Write-Host "You might be prompted for your administrator password."
        try {
            # Execute both commands commonly used on macOS
            sudo dscacheutil -flushcache
            $exitCode1 = $LASTEXITCODE
            sudo killall -HUP mDNSResponder
            $exitCode2 = $LASTEXITCODE

            if ($exitCode1 -eq 0 -and $exitCode2 -eq 0) {
                Write-Host "macOS DNS cache successfully flushed." -ForegroundColor Green
            } else {
                Write-Warning "One or both macOS DNS flush commands failed. dscacheutil exit: $exitCode1, killall exit: $exitCode2"
            }
        } catch {
            Write-Error "Failed to execute DNS flush commands on macOS. Ensure sudo privileges are available."
            Write-Error $_.Exception.Message
        }

    } elseif ($IsLinux) {
        Write-Host "Operating System: Linux (detected via `$IsLinux)"
        Write-Host "Attempting to flush DNS using systemd-resolved..."
        Write-Host "Executing: sudo systemd-resolve --flush-caches"
        Write-Host "You might be prompted for your administrator password."
        Write-Host "Note: This command works for systems using systemd-resolved (common on modern Ubuntu, Fedora, etc.)."
        Write-Host "If this fails, your system might use nscd ('sudo /etc/init.d/nscd restart' or 'sudo systemctl restart nscd') or dnsmasq ('sudo /etc/init.d/dnsmasq restart' or 'sudo systemctl restart dnsmasq')."
        try {
            sudo systemd-resolve --flush-caches
            $exitCodeFlush = $LASTEXITCODE
            # Check the exit code of the last command
            if ($exitCodeFlush -eq 0) {
                 Write-Host "Linux DNS cache (systemd-resolved) successfully flushed." -ForegroundColor Green
                 # Some versions might also benefit from restarting the service
                 Write-Host "Additionally attempting to restart systemd-resolved service..."
                 sudo systemctl restart systemd-resolved.service
                 $exitCodeRestart = $LASTEXITCODE
                 if ($exitCodeRestart -eq 0) {
                    Write-Host "systemd-resolved service restarted successfully." -ForegroundColor Green
                 } else {
                    Write-Warning "Could not restart systemd-resolved service (Exit Code: $exitCodeRestart). Flushing cache might still have been successful."
                 }
            } else {
                 Write-Warning "Command 'systemd-resolve --flush-caches' failed or is not available (Exit Code: $exitCodeFlush). Check if systemd-resolved is in use or try alternative commands mentioned above."
            }
        } catch {
            Write-Error "Failed to execute DNS flush command on Linux. Ensure sudo privileges are available and the command is correct for your distribution's DNS service."
            Write-Error $_.Exception.Message
        }

    } else {
        # This case should theoretically not be hit if IsWindows/IsMacOS/IsLinux cover all supported platforms for PS 6+
        Write-Error "Unrecognized operating system within PowerShell 6+ environment despite automatic variables."
    }

} else {
    # Running PowerShell 5.1 or lower (likely Windows PowerShell 'Desktop' Edition)
    Write-Host "Using legacy PowerShell detection (version less than 6)."

    # Check if it appears to be Windows PowerShell on Windows
    if ($PSVersionTable.PSEdition -eq 'Desktop' -and $PSVersionTable.Platform -eq 'Win32NT') {
         Write-Host "Operating System: Windows (legacy detection)"
         Clear-WindowsDns # Call the function for Windows DNS flush
    } else {
        # PS 5.1 or lower doesn't run natively on macOS/Linux in a standard way.
        # If it's Core edition on Linux/Mac (rare older setup), it would need PS 6+ logic.
        Write-Error "This script requires PowerShell 6+ to run reliably on non-Windows platforms or PowerShell Core editions below 6.0."
        Write-Error "Your current PowerShell edition/platform ($($PSVersionTable.PSEdition) / $($PSVersionTable.Platform)) on this older version is not supported for automated cross-platform execution."
        exit 1
    }
}

Write-Host "-------------------------------------"
Write-Host "Script execution finished."