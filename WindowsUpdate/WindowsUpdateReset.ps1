<#
.SYNOPSIS
    Resets Windows Update components to troubleshoot update issues.
.DESCRIPTION
    This script stops relevant services, clears caches and registration data,
    resets network configurations related to updates, and restarts services.
    It is designed for Windows 10, Windows 11, Windows Server 2016 and newer.
    Run this script with Administrator privileges.
.NOTES
    Date: 2025-04-02
    Version: 2.0

    WARNING: This script performs significant changes to the Windows Update configuration.
    Use it only when troubleshooting persistent update failures. A reboot is recommended afterwards.

    Removed Steps from Original Script:
    - Obsolete WUA agent installation (KB2937636).
    - Mass DLL re-registration via regsvr32.exe (often unnecessary/problematic on modern OS).
    - Deletion of legacy WindowsUpdate.log file.
    - Architecture check (no longer needed for removed WUA install).
.EXAMPLE
    .\Reset-WindowsUpdate_v2.ps1 -Verbose
    Runs the script and shows detailed step-by-step progress messages.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
[Alias("Reset-WU")]
param()

#region Script Requirements
#Requires -RunAsAdministrator
#Requires -Modules BitsTransfer, NetTCPIP # Implicit dependency for Get-NetIPConfiguration/netsh
#endregion Script Requirements

Write-Verbose "Starting Windows Update reset process."

#region Stop Services
Write-Verbose "Step 1: Stopping required services..."
$servicesToStop = @(
    "BITS",       # Background Intelligent Transfer Service
    "wuauserv",   # Windows Update
    "cryptSvc",   # Cryptographic Services (needed to clear catroot2)
    "msiserver"  # Windows Installer (sometimes holds files needed for updates)
    # "appidsvc" # Application Identity - Less commonly needed, uncomment if required
)

foreach ($serviceName in $servicesToStop) {
    Write-Verbose "--> Stopping service: $serviceName"
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -ne 'Stopped') {
            # Stop dependent services first if stopping BITS or wuauserv
            if ($PSCmdlet.ShouldProcess("Service '$serviceName'", "Stop")) {
                 Stop-Service -Name $serviceName -Force -ErrorAction Stop
                 Write-Verbose "    Service '$serviceName' stopped."
             }
        } else {
            Write-Verbose "    Service '$serviceName' is already stopped."
        }
    } catch {
        Write-Warning "Could not stop service '$serviceName'. Error: $($_.Exception.Message)"
    }
    # Give msiserver a moment if it was stopped
    if ($serviceName -eq "msiserver") { Start-Sleep -Seconds 2 }
}
#endregion Stop Services

#region Clear BITS Queue
# Clear any pending BITS jobs which might be corrupted
Write-Verbose "Step 2: Clearing BITS (Background Intelligent Transfer Service) queue..."
try {
    $bitsJobs = Get-BitsTransfer -ErrorAction SilentlyContinue # Check if any exist first
    if ($null -ne $bitsJobs) {
         if ($PSCmdlet.ShouldProcess("All BITS Jobs", "Remove")) {
            Write-Verbose "--> Removing existing BITS jobs."
            $bitsJobs | Remove-BitsTransfer -ErrorAction Stop
            Write-Verbose "    BITS queue cleared."
         }
    } else {
        Write-Verbose "    No active BITS jobs found."
    }
} catch {
    Write-Warning "Could not clear BITS queue. Error: $($_.Exception.Message)"
}
# Remove old QMGR dat files (alternative way BITS stores queue info)
$qmgrPath = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\Network\Downloader"
if (Test-Path -Path $qmgrPath) {
    Write-Verbose "--> Removing QMGR data files from $qmgrPath"
    try {
        if ($PSCmdlet.ShouldProcess("$qmgrPath\qmgr*.dat", "Remove")) {
             Remove-Item -Path (Join-Path -Path $qmgrPath -ChildPath "qmgr*.dat") -Force -ErrorAction Stop
             Write-Verbose "    QMGR data files removed."
        }
    } catch {
        Write-Warning "Could not remove QMGR data files. Error: $($_.Exception.Message). This might be okay if no files existed."
    }
} else {
     Write-Verbose "    QMGR path ($qmgrPath) not found, skipping QMGR file removal."
}

#endregion Clear BITS Queue

#region Rename Cache Folders
Write-Verbose "Step 3: Renaming SoftwareDistribution and Catroot2 folders..."
$sdPath = Join-Path -Path $env:SystemRoot -ChildPath "SoftwareDistribution"
$crPath = Join-Path -Path $env:SystemRoot -ChildPath "System32\Catroot2"

foreach ($folderPath in @($sdPath, $crPath)) {
    $backupPath = "$($folderPath).bak"
    Write-Verbose "--> Processing folder: $folderPath"
    if (Test-Path -Path $folderPath) {
        Write-Verbose "    Attempting to rename to: $backupPath"
        # Remove existing backup folder first if it exists
        if (Test-Path -Path $backupPath) {
             Write-Verbose "    Removing existing backup folder: $backupPath"
              if ($PSCmdlet.ShouldProcess($backupPath, "Remove existing backup")) {
                 try {
                     Remove-Item -Path $backupPath -Recurse -Force -ErrorAction Stop
                 } catch {
                     Write-Warning "Could not remove existing backup folder '$backupPath'. Error: $($_.Exception.Message). Manual deletion might be required."
                     # Continue to renaming attempt anyway, maybe it's just a file lock issue
                 }
             }
        }
        # Try renaming the main folder
         if ($PSCmdlet.ShouldProcess("$folderPath to $backupPath", "Rename")) {
            try {
                Rename-Item -Path $folderPath -NewName "$($folderPath.Split('\')[-1]).bak" -Force -ErrorAction Stop
                Write-Verbose "    Folder '$folderPath' successfully renamed to '$backupPath'."
            } catch {
                Write-Warning "Could not rename folder '$folderPath'. Error: $($_.Exception.Message). Check for file locks or permissions issues."
            }
        }
    } else {
        Write-Verbose "    Folder '$folderPath' does not exist, skipping rename."
    }
}
#endregion Rename Cache Folders

#region Reset Service Security Descriptors (Optional but sometimes needed)
Write-Verbose "Step 4: Resetting Windows Update service security descriptors to defaults..."
# This can help if service permissions were corrupted. Uses original SDDL strings.
$sddlStrings = @{
    bits     = "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
    wuauserv = "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
}

foreach ($service in $sddlStrings.Keys) {
    Write-Verbose "--> Resetting SDDL for service: $service"
     if ($PSCmdlet.ShouldProcess("Service '$service' Security Descriptor", "Reset via sc.exe")) {
        try {
            sc.exe sdset $service $sddlStrings[$service] # No easy native PowerShell equivalent for sdset
            Write-Verbose "    Security descriptor reset for '$service'."
        } catch {
            Write-Warning "Failed to reset security descriptor for service '$service'. Error: $($_.Exception.Message)"
        }
    }
}
#endregion Reset Service Security Descriptors

#region Reset Network Components
Write-Verbose "Step 5: Resetting network components (WinSock and WinHTTP Proxy)..."
Write-Verbose "--> Resetting WinSock..."
 if ($PSCmdlet.ShouldProcess("WinSock", "Reset via netsh")) {
    try {
        netsh.exe winsock reset | Out-Null # Suppress output from netsh
        Write-Verbose "    WinSock reset successfully. A reboot is needed to complete the reset."
    } catch {
        Write-Warning "WinSock reset command failed. Error: $($_.Exception.Message)"
    }
}

Write-Verbose "--> Resetting WinHTTP proxy settings..."
 if ($PSCmdlet.ShouldProcess("WinHTTP Proxy", "Reset via netsh")) {
    try {
        netsh.exe winhttp reset proxy | Out-Null # Suppress output from netsh
        Write-Verbose "    WinHTTP proxy reset successfully."
    } catch {
        Write-Warning "WinHTTP proxy reset command failed. Error: $($_.Exception.Message)"
    }
}
#endregion Reset Network Components

#region Remove Specific WSUS Client Registry Keys (Optional)
# This helps force re-registration with WSUS if used. Safe to run even if not using WSUS.
Write-Verbose "Step 6: Removing specific WSUS client identification registry keys..."
$wuRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate"
$regKeysToRemove = @(
    "AccountDomainSid",
    "PingID",
    "SusClientId",
    "SusClientIdValidation" # Also remove this one
)

if (Test-Path $wuRegPath) {
    foreach ($keyName in $regKeysToRemove) {
        Write-Verbose "--> Checking for registry value: $keyName"
        $prop = Get-ItemProperty -Path $wuRegPath -Name $keyName -ErrorAction SilentlyContinue
        if ($null -ne $prop) {
            Write-Verbose "    Found '$keyName'. Attempting removal."
            if ($PSCmdlet.ShouldProcess("Registry Value '$keyName' under '$wuRegPath'", "Remove")) {
                try {
                    Remove-ItemProperty -Path $wuRegPath -Name $keyName -Force -ErrorAction Stop
                    Write-Verbose "    Registry value '$keyName' removed."
                } catch {
                    Write-Warning "Could not remove registry value '$keyName'. Error: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Verbose "    Registry value '$keyName' not found."
        }
    }
} else {
    Write-Verbose "    Windows Update registry path ($wuRegPath) not found. Skipping WSUS key removal."
}
#endregion Remove Specific WSUS Client Registry Keys

#region Start Services
Write-Verbose "Step 7: Starting stopped services..."
# Start CryptSvc and msiserver first if they were stopped
if ("cryptSvc" -in $servicesToStop) {
    Write-Verbose "--> Starting service: cryptSvc"
    try {
        if ($PSCmdlet.ShouldProcess("Service 'cryptSvc'", "Start")) {
             Start-Service -Name "cryptSvc" -ErrorAction Stop
             Write-Verbose "    Service 'cryptSvc' started."
         }
    } catch {
        Write-Warning "Could not start service 'cryptSvc'. Error: $($_.Exception.Message)"
    }
}
if ("msiserver" -in $servicesToStop) {
     Write-Verbose "--> Ensuring service 'msiserver' is stopped (it's usually demand-start)"
     # Don't try to start msiserver, just ensure it's not running if we stopped it.
     # It will start on demand when needed. Let's check its status.
      try {
         $msiService = Get-Service -Name "msiserver" -ErrorAction Stop
         if ($msiService.Status -ne 'Stopped') {
             Write-Verbose "    Stopping 'msiserver' again just in case."
             Stop-Service -Name "msiserver" -Force -ErrorAction SilentlyContinue
         }
      } catch {
          Write-Verbose "    Could not check status of 'msiserver'. It might not be present."
      }
}


# Start core WU services
$servicesToStart = @("BITS", "wuauserv")
foreach ($serviceName in $servicesToStart) {
    if ($serviceName -in $servicesToStop) { # Only start if we attempted to stop it
        Write-Verbose "--> Starting service: $serviceName"
        try {
             if ($PSCmdlet.ShouldProcess("Service '$serviceName'", "Start")) {
                Start-Service -Name $serviceName -ErrorAction Stop
                Write-Verbose "    Service '$serviceName' started."
             }
        } catch {
            Write-Warning "Could not start service '$serviceName'. Error: $($_.Exception.Message). Manual start might be required."
        }
    }
}
#endregion Start Services

#region Trigger Detection (Modern Method)
Write-Verbose "Step 8: Attempting to trigger a Windows Update detection scan..."
# Use UsoClient (Update Session Orchestrator) - primary method from Win10 onwards
$usoClientPath = Join-Path -Path $env:SystemRoot -ChildPath "System32\UsoClient.exe"
if (Test-Path $usoClientPath) {
     Write-Verbose "--> Using UsoClient.exe StartScan"
      if ($PSCmdlet.ShouldProcess("UsoClient.exe StartScan", "Execute")) {
        try {
            # Start the process but don't wait indefinitely. A scan can take time.
            Start-Process -FilePath $usoClientPath -ArgumentList "StartScan" -NoNewWindow -ErrorAction Stop
            Write-Verbose "    UsoClient.exe StartScan command issued."
        } catch {
             Write-Warning "Could not execute UsoClient.exe StartScan. Error: $($_.Exception.Message). Try checking for updates manually."
        }
     }
} else {
    Write-Warning "UsoClient.exe not found at '$usoClientPath'. Cannot trigger scan automatically. Check for updates manually via Settings or run 'Install-Module PSWindowsUpdate -Force; Get-WindowsUpdate -Scan' (requires PowerShell Gallery access)."
    # Fallback: Try the old wuauclt /detectnow - might do something on some builds, no harm trying.
    Write-Verbose "--> Attempting fallback with deprecated wuauclt.exe /detectnow"
    $wuaucltPath = Join-Path -Path $env:SystemRoot -ChildPath "System32\wuauclt.exe"
    if (Test-Path $wuaucltPath) {
         if ($PSCmdlet.ShouldProcess("wuauclt.exe /resetauthorization /detectnow", "Execute deprecated fallback")) {
            try {
                Start-Process -FilePath $wuaucltPath -ArgumentList "/resetauthorization /detectnow" -NoNewWindow -ErrorAction Stop
                Write-Verbose "    Deprecated wuauclt.exe command issued."
            } catch {
                 Write-Warning "Could not execute deprecated wuauclt.exe. Error: $($_.Exception.Message)"
            }
         }
    } else {
         Write-Verbose "    wuauclt.exe not found, cannot attempt fallback."
    }
}
#endregion Trigger Detection

Write-Host "`n------------------------------------------------------------------" -ForegroundColor Green
Write-Host "Windows Update reset process completed." -ForegroundColor Green
Write-Host "RECOMMENDATION: Please REBOOT your computer now to ensure all changes take effect." -ForegroundColor Yellow
Write-Host "After rebooting, manually check for Windows Updates." -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------" -ForegroundColor Green