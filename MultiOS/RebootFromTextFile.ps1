<#
.SYNOPSIS
Reboots remote Windows computers listed in a specified text file. Designed for cross-platform use with PowerShell Core 7+.

.DESCRIPTION
This script reads a list of computer names from a text file and attempts to reboot each one using the Restart-Computer cmdlet.
It prompts for credentials to use for the remote connection.
It assumes the target computers are Windows machines with WinRM enabled and configured for remote management from the machine running this script.

.PARAMETER ComputerListPath
The path to the text file containing the list of computer names (one per line). Defaults to './servers.txt' in the current directory.

.EXAMPLE
.\Reboot-RemoteWindows.ps1

Runs the script using the default './servers.txt' file and prompts for credentials.

.EXAMPLE
.\Reboot-RemoteWindows.ps1 -ComputerListPath "C:\Admin\MyServers.txt"

Runs the script using the specified file path and prompts for credentials.

.NOTES
- Requires PowerShell Core (7.0 or later) installed on the machine running the script (Windows, Linux, or macOS).
- Requires WinRM to be enabled and configured on the target Windows servers.
- Firewall rules must allow WinRM traffic (Default ports: 5985/HTTP, 5986/HTTPS).
- Appropriate permissions are needed on the target servers for the provided credentials.
- For Linux/macOS -> Windows or non-domain Windows -> Windows, WinRM configuration (TrustedHosts, HTTPS/Basic Auth, or Kerberos) is crucial.
- The script reboots computers sequentially. For parallel execution, consider using Start-Job or ForEach-Object -Parallel.
#>
param(
    [Parameter(Mandatory=$false)]
    [string]$ComputerListPath = "./servers.txt"
)

# Verify PowerShell Version (Optional but recommended)
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "This script is designed for PowerShell Core 7 or later. You are running $($PSVersionTable.PSVersion). Compatibility issues may arise."
}

# Check if the computer list file exists
if (-not (Test-Path -Path $ComputerListPath -PathType Leaf)) {
    Write-Error "Computer list file not found at path: $ComputerListPath"
    # Exit the script if the file doesn't exist
    Exit 1
}

# Prompt for credentials
Write-Host "Please enter credentials needed to reboot the remote Windows servers."
Write-Host "Use format like 'DOMAIN\Username', 'Username@domain.com', or 'TARGETCOMPUTER\Username' (for local accounts)."
$PSCredential = Get-Credential

# Read the list of servers from the file
try {
    $Servers = Get-Content -Path $ComputerListPath -ErrorAction Stop
} catch {
    Write-Error "Error reading computer list file '$ComputerListPath': $($_.Exception.Message)"
    Exit 1
}

# Process each server in the list
Write-Host "Starting reboot process..."
foreach ($serverName in $Servers) {
    # Trim whitespace and skip empty lines
    $serverName = $serverName.Trim()
    if ([string]::IsNullOrWhiteSpace($serverName)) {
        Write-Verbose "Skipping empty line."
        continue
    }

    Write-Host "Attempting to reboot '$serverName'..."
    try {
        # Attempt to reboot the remote computer
        # Requires WinRM enabled and configured for authentication on the target machine.
        # -Force suppresses the confirmation prompt.
        # -Delay adds a short wait time on the target before reboot starts.
        Restart-Computer -ComputerName $serverName -Credential $PSCredential -Force -Delay 5 -ErrorAction Stop

        Write-Host "Reboot command successfully sent to '$serverName'."

    } catch {
        # Catch errors (e.g., network issues, access denied, WinRM not configured)
        Write-Warning "Failed to reboot '$serverName'. Error: $($_.Exception.Message)"
        # You might want to add more detailed error logging here if needed
        # Write-Warning $_.ScriptStackTrace
    }
    # Optional: Add a small pause between attempts
    # Start-Sleep -Seconds 2
}

Write-Host "Script finished processing all servers in the list."
Exit 0