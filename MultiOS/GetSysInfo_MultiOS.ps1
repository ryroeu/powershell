<#
.SYNOPSIS
    Retrieves system information across multiple operating systems.
#>

#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Detects the operating system, displays system hardware information, and saves it to a text file on the desktop.

.DESCRIPTION
    This script checks if it is running on Windows, Linux, or macOS and then runs OS-specific commands 
    to display hardware details such as CPU, memory, disk, and more. The complete output is captured and 
    saved by default to "HardwareInfo.txt" on the user’s desktop.
    
    **Note:** On Linux and macOS some commands (like `lshw` or `system_profiler`) may not be installed 
    by default or might require elevated privileges.

.NOTES
    Requires PowerShell Core (pwsh) version 6 or above.
#>

# Determine the Desktop path for output
if ($IsWindows) {
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
}
else {
    $desktopPath = "$HOME/Desktop"
    if (-not (Test-Path $desktopPath)) {
        New-Item -ItemType Directory -Path $desktopPath | Out-Null
    }
}

$outFile = Join-Path $desktopPath "HardwareInfo.txt"

# Start transcript to capture all output to the file
Start-Transcript -Path $outFile -Force

# Function to check if a command exists in the current session
function Test-CommandExistence {
    param(
        [string]$CommandName
    )
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        return $true
    }
    return $false
}

if ($IsWindows) {
    Write-Output "Operating System: Windows"
    Write-Output "Collecting hardware information..."

    Write-Output "`n=== Computer System Information ==="
    Get-CimInstance -ClassName Win32_ComputerSystem | Format-List

    Write-Output "`n=== Processor Information ==="
    Get-CimInstance -ClassName Win32_Processor | Format-List

    Write-Output "`n=== Physical Memory Information ==="
    Get-CimInstance -ClassName Win32_PhysicalMemory | Format-List

    Write-Output "`n=== Disk Drive Information ==="
    Get-CimInstance -ClassName Win32_DiskDrive | Format-List

    Write-Output "`n=== Video Controller Information ==="
    Get-CimInstance -ClassName Win32_VideoController | Format-List
}
elseif ($IsLinux) {
    Write-Output "Operating System: Linux"
    Write-Output "Collecting hardware information..."

    if (Test-CommandExistence "lscpu") {
        Write-Output "`n=== CPU Information ==="
        lscpu
    }
    else {
        Write-Output "lscpu command not found."
    }

    if (Test-CommandExistence "free") {
        Write-Output "`n=== Memory Information ==="
        free -h
    }
    else {
        Write-Output "free command not found."
    }

    if (Test-CommandExistence "lsblk") {
        Write-Output "`n=== Disk Information ==="
        lsblk
    }
    else {
        Write-Output "lsblk command not found."
    }

    if (Test-CommandExistence "lshw") {
        Write-Output "`n=== Detailed Hardware Information ==="
        # lshw may require sudo privileges if not run as root
        if ($EUID -ne 0) {
            Write-Output "Note: Running 'lshw' may require sudo privileges. Attempting to run with sudo..."
            sudo lshw -short
        }
        else {
            lshw -short
        }
    }
    else {
        Write-Output "lshw command not found."
    }
}
elseif ($IsMacOS) {
    Write-Output "Operating System: macOS"
    Write-Output "Collecting hardware information..."

    if (Test-CommandExistence "system_profiler") {
        Write-Output "`n=== Hardware Overview ==="
        system_profiler SPHardwareDataType

        Write-Output "`n=== Network Information ==="
        system_profiler SPNetworkDataType

        Write-Output "`n=== Storage Information ==="
        system_profiler SPStorageDataType
    }
    else {
        Write-Output "system_profiler command not found."
    }
}
else {
    Write-Output "Unsupported operating system."
}

# End transcript to finalize the file
Stop-Transcript