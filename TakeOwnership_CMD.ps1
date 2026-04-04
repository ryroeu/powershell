<#
.SYNOPSIS
    Takes ownership cmd.
#>

﻿function Set-AdminOwnershipAndPermission {
    [CmdletBinding(SupportsShouldProcess=$true)] # Adds -WhatIf and -Confirm support
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path
    )

    # --- Pre-Checks ---
    # Check if running as Administrator
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run with Administrator privileges." -ErrorAction Stop
    }

    # Check if path exists
    if (-not (Test-Path $Path)) {
         Write-Error "The specified path '$Path' does not exist." -ErrorAction Stop
    }

    # Use $PSCmdlet.ShouldProcess for -WhatIf / -Confirm
    if ($PSCmdlet.ShouldProcess($Path, "Take Ownership and Grant Full Control to Administrators")) {
        Write-Host "Attempting to take ownership of '$Path' recursively..."
        try {
            # Execute takeown
            takeown /R /A /F $Path /D Y # Changed /D N to /D Y to suppress prompt by default
            if ($LASTEXITCODE -ne 0) {
                 Write-Warning "takeown command finished with exit code $LASTEXITCODE. There might have been issues."
                 # Depending on severity, you might want to stop here:
                 # throw "takeown failed with exit code $LASTEXITCODE"
            } else {
                Write-Host "Ownership taken successfully (or command completed)."
            }

            Write-Host "Attempting to grant Administrators Full Control on '$Path' recursively..."
            # Execute icacls
            icacls $Path /grant Administrators:F /T /C
             if ($LASTEXITCODE -ne 0) {
                 Write-Warning "icacls command finished with exit code $LASTEXITCODE. There might have been issues granting permissions."
                 # throw "icacls failed with exit code $LASTEXITCODE"
            } else {
                 Write-Host "Permissions granted successfully (or command completed)."
            }
        }
        catch {
             Write-Error "An error occurred while executing external commands: $($_.Exception.Message)"
        }
    }
}

# --- How to use the function ---
# Save the code above as a .ps1 file (e.g., Set-Permissions.ps1)
# Dot-source it in your PowerShell session: . .\Set-Permissions.ps1
# Then call the function:
# Set-AdminOwnershipAndPermissions -Path "C:\Path\To\Your\foldername"
# Or use -WhatIf to see what would happen:
# Set-AdminOwnershipAndPermissions -Path "C:\Path\To\Your\foldername" -WhatIf