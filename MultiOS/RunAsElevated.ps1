<#
.SYNOPSIS
Ensures the script runs with elevated privileges (Administrator on Windows, root on Linux/macOS).
Relaunches itself requesting elevation if not already elevated.

.DESCRIPTION
This script checks if it's currently running with administrative/root privileges.
- On Windows, it checks if the user is in the Administrator role. If not, it uses Start-Process with the 'RunAs' verb to relaunch itself via UAC.
- On Linux/macOS, it checks if the effective user ID is 0 (root). If not, it uses 'sudo' to relaunch itself.

It preserves any arguments originally passed to the script during the relaunch.
If already elevated, it indicates this in the window title and proceeds with the main script logic.

.NOTES
Date: 2025-04-02
Requires: PowerShell 7+ for cross-platform compatibility ($IsLinux, $IsMacOs variables).
          On Linux/macOS, the 'sudo' command must be available and configured for the user.
#>

param() # Ensures $args captures script arguments correctly

# --- Elevation Check and Relaunch Logic ---

$needsElevation = $false
$isElevated = $false

# Determine the path to the current PowerShell executable
# $PSEdition check is for older PS versions, $IsCoreCLR is more reliable in PS 6+
# $PSHOME ensures we get the correct path even if invoked via just 'pwsh' or 'powershell'
if ($IsWindows) {
    # Get the security principal for the Administrator role
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    # Get the identity and principal of the current user account
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = [System.Security.Principal.WindowsPrincipal]$currentUser

    if (-not $windowsPrincipal.IsInRole($adminRole)) {
        $needsElevation = $true
    } else {
        $isElevated = $true
    }
    # Determine executable based on current session
    $pwshExe = if ($IsCoreCLR) { "$PSHOME\pwsh.exe" } else { "$PSHOME\powershell.exe" }

} elseif ($IsLinux -or $IsMacOS) {
    # Check if effective user ID is 0 (root)
    # Using 'id -u' is a common cross-unix way
    $currentUserId = (id -u)
    if ($currentUserId -ne 0) {
        Write-Warning "Script requires root privileges to run correctly."
        # Check if sudo exists
        if (Get-Command sudo -ErrorAction SilentlyContinue) {
             $needsElevation = $true
        } else {
            Write-Error "Could not find 'sudo'. Please run this script using 'sudo pwsh ...'"
            exit 1 # Exit if sudo isn't available and elevation is needed
        }
    } else {
        $isElevated = $true
    }
    # PowerShell Core executable on Linux/macOS is 'pwsh'
    $pwshExe = "$PSHOME/pwsh"

} else {
    Write-Warning "Unsupported operating system for automatic elevation check."
    # Allow script to continue, but elevation cannot be guaranteed.
    # You might want to exit here depending on requirements:
    # exit 1
}

# Relaunch if elevation is needed
if ($needsElevation) {
    Write-Warning "Attempting to relaunch script with elevated privileges..."

    # Prepare arguments for the new process
    # Pass the original script file path and any arguments it received
    # Quote the script path in case it contains spaces
    $processArgs = @("-File", "`"$PSCommandPath`"") + $args

    if ($IsWindows) {
        try {
            # Relaunch using UAC
            Start-Process -FilePath $pwshExe -ArgumentList $processArgs -Verb RunAs -ErrorAction Stop
        } catch {
            Write-Error "Failed to relaunch script with elevation. Error: $($_.Exception.Message)"
            Write-Error "Please run the script manually from an Administrator PowerShell session."
            exit 1
        }
    } elseif ($IsLinux -or $IsMacOS) {
        # Build the full command string for sudo
        $sudoArgs = @("`"$pwshExe`"") + $processArgs -join " "
        try {
            # Relaunch using sudo
            # Note: Start-Process isn't ideal for interactive sudo password prompt handling in all terminals.
            # A direct call might be needed in complex scenarios, but Start-Process keeps it consistent.
            # Consider potential issues with how different terminals handle sudo password prompts via Start-Process.
            Start-Process -FilePath "sudo" -ArgumentList $sudoArgs -ErrorAction Stop
            # Alternatively, for potentially better interactive password handling:
            # Invoke-Expression "sudo $sudoArgs"
        } catch {
             Write-Error "Failed to relaunch script with elevation using 'sudo'. Error: $($_.Exception.Message)"
             Write-Error "Please run the script manually using: sudo `"$pwshExe`" `"$PSCommandPath`" arguments..."
             exit 1
        }
    }

    # Exit the current non-elevated process
    exit
}

# --- Elevated Code Execution ---

if ($isElevated) {
    # Indicate elevation (optional, adjust as needed)
    $originalTitle = $Host.UI.RawUI.WindowTitle
    $Host.UI.RawUI.WindowTitle = "$originalTitle (Elevated)"
    Write-Host "Script is running with elevated privileges." -ForegroundColor Green

    # Trap script exit/termination to restore the original title
    trap {
        # Restore original window title on exit/error
        $Host.UI.RawUI.WindowTitle = $originalTitle
        # Break the trap to allow normal error handling/exit
        break
    }
}

# --- !!! START YOUR ELEVATED CODE BELOW THIS LINE !!! ---

Write-Host "Executing the main part of the script..."
Write-Host "Arguments received: $($args -join ', ')" # Example: Show arguments

# Example elevated command:
Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object -First 5

Write-Host "Script finished."

# Restore original window title if the script completes normally
if ($isElevated) {
    $Host.UI.RawUI.WindowTitle = $originalTitle
}

# --- !!! END YOUR ELEVATED CODE ABOVE THIS LINE !!! ---