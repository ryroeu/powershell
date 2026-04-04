<#
.SYNOPSIS
    Stops all nondefault Windows service.
#>

#requires -Version 5.1 
# Although compatible with Core 7+, setting a baseline. 
# Requires running as Administrator to stop services.

<#
.SYNOPSIS
Identifies and attempts to stop services deemed "non-default" based on specific criteria.

.DESCRIPTION
This script retrieves Windows services, filters them based on DisplayName, PathName,
and Name properties to exclude common Windows and Microsoft services, and then
attempts to stop the remaining services. It waits for each service to confirm
it has stopped before proceeding, with a timeout.

WARNING: Stopping services can have unintended consequences. Ensure you understand
         which services are being targeted and the potential impact. Run with caution.
         Requires Administrator privileges.

.NOTES
Date:    2025-04-04
#>

# Define parameters for flexibility
[CmdletBinding(SupportsShouldProcess = $true)] # Adds -WhatIf and -Confirm support
param(
    [int]$TimeoutSeconds = 90 # Max time to wait for a service to stop
)

Write-Verbose "Starting script execution."
Write-Verbose "Script requires Administrator privileges to stop services."

# --- Filter Definition ---
# Define criteria for services to EXCLUDE (considered "default" or "essential")
# Consider refining this list based on your specific environment needs.
Write-Verbose "Defining filter criteria for services to exclude."
$excludedPatterns = @{
    DisplayName = 'Windows' # Exclude services with "Windows" in DisplayName
    PathName    = @(          # Exclude services with specific paths/executables
        'Windows'                 # Path contains "Windows" (e.g., system32)
        'policyhost.exe'
        'OSE.EXE'                 # Office Source Engine
        'OSPPSVC.EXE'             # Office Software Protection Platform
        'Microsoft Security Client' # Path contains this (older MSE)
        # Add more specific paths or executables to exclude if needed
        # Example: 'Program Files\\Common Files\\Microsoft Shared' 
    )
    Name        = 'LSM'      # Local Session Manager (Essential)
    # Add other essential service names if necessary:
    # Example: 'RpcSs', 'PlugPlay' 
}

# --- Service Identification ---
Write-Verbose "Retrieving and filtering services..."
try {
    $AllServices = Get-Service -ErrorAction Stop
    
    $NonDefaultServices = $AllServices | Where-Object {
        $service = $_
        $isExcluded = $false

        # Check DisplayName exclusion
        if ($service.DisplayName -match $excludedPatterns.DisplayName) {
            $isExcluded = $true
        }

        # Check PathName exclusions (handle potential null/empty PathName)
        if (!$isExcluded -and $service.PathName) {
            foreach ($pattern in $excludedPatterns.PathName) {
                if ($service.PathName -match $pattern) {
                    $isExcluded = $true
                    break # Exit inner loop once a match is found
                }
            }
        }
        
        # Check Name exclusion
        if (!$isExcluded -and $service.Name -eq $excludedPatterns.Name) {
             $isExcluded = $true
        }

        # Return $true if the service should BE INCLUDED (i.e., !$isExcluded)
        -not $isExcluded 
    }

    Write-Host "Found $($NonDefaultServices.Count) non-default services to process." -ForegroundColor Cyan
    if ($NonDefaultServices.Count -gt 0) {
        Write-Verbose "Services identified:"
        $NonDefaultServices | Format-Table Name, DisplayName, Status -AutoSize | Out-String | Write-Verbose
    } else {
        Write-Verbose "No non-default services matching the criteria were found."
        # Exit cleanly if none found
        return 
    }

} catch {
    Write-Error "Failed to retrieve services: $($_.Exception.Message)"
    # Exit script if Get-Service fails
    exit 1
}


# --- Service Stopping Loop ---
Write-Verbose "Attempting to stop identified services..."

foreach ($Service in $NonDefaultServices) {
    
    Write-Host "`nProcessing Service: $($Service.DisplayName) ($($Service.Name))" -ForegroundColor Yellow
    
    # Check current status before attempting to stop
    $currentServiceState = Get-Service -Name $Service.Name -ErrorAction SilentlyContinue
    
    if (!$currentServiceState) {
        Write-Warning "Service $($Service.Name) not found or inaccessible. Skipping."
        continue
    }

    if ($currentServiceState.Status -eq 'Stopped') {
        Write-Host "Service $($Service.Name) is already stopped." -ForegroundColor Green
        continue
    }

    if ($currentServiceState.Status -ne 'Running') {
        Write-Warning "Service $($Service.Name) is not in a 'Running' state (Current: $($currentServiceState.Status)). Skipping stop attempt."
        continue
    }

    Write-Verbose "Attempting to stop service: $($Service.Name)"
    
    # Use -WhatIf / -Confirm support
    if ($PSCmdlet.ShouldProcess("Service '$($Service.DisplayName) ($($Service.Name))'", "Stop")) {
        try {
            # Attempt to stop the service
            Stop-Service -Name $Service.Name -Force -ErrorAction Stop 
            
            Write-Host "Stop command issued for $($Service.Name). Waiting for service to enter 'Stopped' state (Timeout: ${TimeoutSeconds}s)..."

            # Wait loop with timeout
            $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
            $serviceStopped = $false
            
            do {
                $currentState = (Get-Service -Name $Service.Name).Status
                if ($currentState -eq 'Stopped') {
                    $serviceStopped = $true
                    $stopWatch.Stop()
                    Write-Host "Service $($Service.Name) successfully stopped in $($stopWatch.Elapsed.TotalSeconds.ToString('F2')) seconds." -ForegroundColor Green
                    break # Exit the do..while loop
                }
                
                # Check timeout
                if ($stopWatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                    $stopWatch.Stop()
                    Write-Warning "Timeout reached waiting for service $($Service.Name) to stop. Current status: $currentState."
                    break # Exit the do..while loop
                }

                # Wait a short interval before checking again
                Start-Sleep -Seconds 2 
                Write-Verbose "Waiting... Current status of $($Service.Name): $currentState"

            } while (-not $serviceStopped)

        } catch {
            # Catch errors specifically from Stop-Service
            Write-Error "Failed to stop service $($Service.Name): $($_.Exception.Message)"
            # Optionally: Check status again here, as it might have stopped despite an error message
            $finalState = (Get-Service -Name $Service.Name -ErrorAction SilentlyContinue).Status
            Write-Warning "Final status check for $($Service.Name) after error: $finalState"
        }
    } else {
         Write-Host "Skipped stopping service $($Service.Name) due to -WhatIf or user choosing 'No' on -Confirm." -ForegroundColor Yellow
    }
}

Write-Verbose "Script execution finished."