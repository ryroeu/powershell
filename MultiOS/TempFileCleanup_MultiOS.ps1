# Cross-platform Temp Cleanup Script
# Requires PowerShell 6+ (Core)

# This script cleans temporary directories on Windows, Linux, and macOS.
# It requires elevated privileges (Administrator on Windows, root on Linux/macOS) to function correctly.

function Test-Elevated {
    if ($IsWindows) {
        # Check if the current process is running as Administrator.
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning "This script must be run with elevated privileges (as Administrator)."
            Write-Host "Please right-click the script and select 'Run as Administrator', or run 'Start-Process pwsh -Verb runAs -ArgumentList '-File YourScript.ps1''."
            return $false
        }
    }
    elseif ($IsLinux -or $IsMacOS) {
        # Check if the current process is running as root (id -u == 0).
        $userId = & id -u
        if ($userId -ne 0) {
            Write-Warning "This script must be run with elevated privileges (as root)."
            Write-Host "Please re-run the script with 'sudo pwsh -File YourScript.ps1'."
            return $false
        }
    }
    else {
        Write-Warning "Unrecognized operating system. Cannot check for elevation."
        return $false
    }

    Write-Host "Script is running with elevated privileges."
    return $true
}

function Start-Cleanup {
    # --- Cleanup logic starts here ---
    if ($IsWindows) {
        Write-Output "Detected Windows OS. Cleaning temporary directories..."
        
        $windowsPaths = @(
            "$Env:TEMP", # User temp directory
            "C:\Windows\Temp",
            "C:\Windows\SoftwareDistribution\Download"
        )
        
        foreach ($path in $windowsPaths) {
            if (Test-Path $path) {
                try {
                    # Recursively remove all files and subdirectories.
                    # The ErrorAction is set to SilentlyContinue to handle files that are in use.
                    Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Output "Cleaned: $path"
                }
                catch {
                    Write-Warning "Failed to clean $($path): $($_)"
                }
            }
            else {
                Write-Output "Path not found: $path (Skipping)"
            }
        }
    }
    elseif ($IsLinux -or $IsMacOS) {
        Write-Output "Detected Linux/macOS. Cleaning temporary directories..."
        
        $tempPaths = @(
            "/tmp",
            "/var/tmp"
        )
        
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                try {
                    # Recursively remove all files and subdirectories.
                    # This command will skip the directory itself to avoid permissions issues.
                    Remove-Item -Path "$path/*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Output "Cleaned: $path"
                }
                catch {
                    Write-Warning "Failed to clean $($path): $($_)"
                }
            }
            else {
                Write-Output "Path not found: $path (Skipping)"
            }
        }
    }
    else {
        Write-Warning "Unrecognized operating system. Exiting script."
    }
}

# Ensure we have elevated privileges before starting the cleanup.
if (Test-Elevated) {
    Start-Cleanup
}
else {
    Write-Host "Exiting script due to insufficient privileges."
}