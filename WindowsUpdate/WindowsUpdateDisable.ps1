#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Disables Windows update.
#>

Write-Host "Attempting to disable Windows Update services..." -ForegroundColor Yellow

# List of services to disable
$serviceNames = @("UsoSvc", "wuauserv", "WaaSMedicSvc") # Added WaaSMedicSvc as it tries to repair WU

foreach ($serviceName in $serviceNames) {
    Write-Host "Processing service: $serviceName"

    # Check if service exists
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Host "Service $serviceName not found. Skipping." -ForegroundColor Gray
        continue
    }

    # Stop the service (ignore errors if already stopped or cannot be stopped)
    Write-Host " - Attempting to stop $serviceName..."
    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue

    # Disable the service
    Write-Host " - Attempting to disable $serviceName (setting StartupType to Disabled)..."
    try {
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
        Write-Host " - Service $serviceName successfully set to Disabled." -ForegroundColor Green
    } catch {
        Write-Host " - Failed to set StartupType for $serviceName. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Finished attempting to disable Windows Update services." -ForegroundColor Yellow
Write-Host "WARNING: Disabling Windows Update leaves your system vulnerable." -ForegroundColor Red
Write-Host "It is strongly recommended to re-enable updates for security." -ForegroundColor Red