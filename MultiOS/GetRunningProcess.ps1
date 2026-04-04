<#
.SYNOPSIS
Detects the current operating system and lists all running processes using the appropriate command.

.DESCRIPTION
This script checks if it is running on Windows, Linux, or macOS using the built-in
PowerShell variables ($IsWindows, $IsLinux, $IsMacOS). It then executes the
native command for that OS to retrieve a list of running processes.
- Windows: Get-Process
- Linux:   ps aux
- macOS:   ps aux

.NOTES
Requires PowerShell Core (v6+) or PowerShell 7+ for $IsLinux and $IsMacOS variables
to correctly identify Linux and macOS. The script will correctly identify Windows
even on older Windows PowerShell 5.1 versions.

On Linux/macOS, ensure PowerShell (pwsh) is installed and accessible.
#>

# Check the operating system using built-in PowerShell variables
if ($IsWindows) {
    Write-Host "Operating System Detected: Windows"
    Write-Host "Running command: Get-Process"
    # Native PowerShell cmdlet for Windows processes
    Get-Process
}
elseif ($IsLinux) {
    Write-Host "Operating System Detected: Linux"
    Write-Host "Running command: ps aux"
    # Standard Linux command to list all processes
    # Execute the external command 'ps aux'
    ps aux
}
elseif ($IsMacOS) {
    Write-Host "Operating System Detected: macOS"
    Write-Host "Running command: ps aux"
    # Standard macOS (Unix-based) command to list all processes
    # Execute the external command 'ps aux'
    ps aux
}
else {
    # Fallback for unsupported OS or potentially very old PowerShell versions
    # where these variables might not be defined (though unlikely for cross-platform use).
    Write-Warning "Could not reliably determine the operating system (requires PowerShell 6+ for Linux/Mac detection) or it is unsupported by this script."
    # You could attempt a fallback using $PSVersionTable.OS, but it's less direct
    Write-Host "OS Information from PSVersionTable:"
    Write-Host ($PSVersionTable | Out-String)
}

# Script finished message
Write-Host "Process listing complete."