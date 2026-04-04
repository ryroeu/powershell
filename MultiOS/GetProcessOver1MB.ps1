<#
.SYNOPSIS
 Detects the operating system (Windows, Linux, macOS) and lists running
 processes that are using more than 1MB of physical memory (Working Set).
.DESCRIPTION
 This script utilizes PowerShell's built-in OS detection variables.
 It then employs the Get-Process cmdlet, which works across platforms
 when using PowerShell Core (v6+), to retrieve process information.
 It filters processes based on their Working Set size exceeding 1MB and
 displays relevant details like Process ID, Name, and Memory Usage in MB.
 Requires PowerShell Core (v6 or later) to be installed and running on
 Linux and macOS for the Get-Process cmdlet to function correctly.
.NOTES
 Date:  2025-04-02
 Memory Threshold: 1 Megabyte (1 * 1024 * 1024 bytes)
#>

# Define the memory threshold (1 Megabyte)
$memoryThresholdBytes = 1MB # PowerShell understands KB, MB, GB suffixes

Write-Host "--------------------------------------------------"
Write-Host " Process Memory Usage Monitor (> $($memoryThresholdBytes / 1MB) MB) "
Write-Host "--------------------------------------------------"
Write-Host "Timestamp: $(Get-Date)"
Write-Host ""

Write-Host "Detecting Operating System..."

# Check OS using built-in PowerShell variables
if ($IsWindows) {
    Write-Host "Operating System: Windows"
}
elseif ($IsLinux) {
    Write-Host "Operating System: Linux (Requires PowerShell Core v6+)"
}
elseif ($IsMacOS) {
    Write-Host "Operating System: macOS (Requires PowerShell Core v6+)"
}
else {
    Write-Error "Unsupported or unknown operating system."
    Write-Host "This script relies on PowerShell variables \$IsWindows, \$IsLinux, or \$IsMacOs."
    exit 1 # Exit script if OS is not detected
}

Write-Host "Attempting to retrieve processes using more than $($memoryThresholdBytes / 1MB) MB of memory..."
Write-Host ""

try {
    # Get-Process is the standard PowerShell cmdlet.
    # It is cross-platform in PowerShell Core (v6+).
    # The 'WorkingSet' property represents the physical memory used by the process.
    $processes = Get-Process | Where-Object { $_.WorkingSet -gt $memoryThresholdBytes }

    if ($null -ne $processes) {
        Write-Host "Processes found:"
        # Select relevant properties and format output
        # Calculate WorkingSet in MB for easier reading
        $processes | Select-Object -Property Id, `
                                          ProcessName, `
                                          @{Name='Memory_WS(MB)'; Expression = {[math]::Round($_.WorkingSet / 1MB, 2)}}, `
                                          Responding | Format-Table -AutoSize

        # You can uncomment the line below for more detailed (but less tidy) output:
        # $processes | Format-List Id, ProcessName, WorkingSet, Path, StartTime
    } else {
        Write-Host "No running processes found using more than $($memoryThresholdBytes / 1MB) MB of memory."
    }
}
catch {
    Write-Error "An error occurred while executing Get-Process: $($_.Exception.Message)"
    Write-Host "Details: $_"
    if ($IsLinux -or $IsMacOS) {
        Write-Warning "Ensure PowerShell Core (v6 or later) is installed and you have permissions to list processes."
        Write-Warning "As a fallback, you might try native commands:"
        Write-Warning "Linux:   ps aux --no-headers | awk '\$6 > 1024'" # 1MB = 1024 KB, RSS is often column 6
        Write-Warning "macOS:   ps aux | awk 'NR > 1 && \$6 > 1024'"   # 1MB = 1024 KB, RSS is often column 6
    }
     if ($IsWindows -and ($PSVersionTable.PSVersion.Major -lt 6)) {
         Write-Warning "You might be running an older version of Windows PowerShell."
     }
}

Write-Host ""
Write-Host "--------------------------------------------------"
Write-Host " Script execution finished. "
Write-Host "--------------------------------------------------"

# End of script
