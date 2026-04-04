#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables Windows update.
#>

Write-Host "Attempting to re-enable Windows Update services..." -ForegroundColor Yellow

# Service names and their typical default StartupTypes
# wuauserv: Manual (Trigger Start) - effectively Manual
# UsoSvc: Automatic (Delayed Start)
# WaaSMedicSvc: Manual
$servicesToEnable = @{
    "wuauserv"     = "Manual"
    "UsoSvc"       = "Automatic" # Will usually result in Automatic (Delayed Start)
    "WaaSMedicSvc" = "Manual"
}

foreach ($serviceName in $servicesToEnable.Keys) {
    Write-Host "Processing service: $serviceName"
    $targetStartupType = $servicesToEnable[$serviceName]

    # Check if service exists
     $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Host "Service $serviceName not found. Skipping." -ForegroundColor Gray
        continue
    }

    # Set the StartupType
    Write-Host " - Attempting to set StartupType for $serviceName to $targetStartupType..."
    try {
        Set-Service -Name $serviceName -StartupType $targetStartupType -ErrorAction Stop
        Write-Host " - Service $serviceName successfully set to $targetStartupType." -ForegroundColor Green

        # Optionally try to start the main WU service if it was set successfully
        if ($serviceName -eq "wuauserv" -and $?) {
             Write-Host " - Attempting to start wuauserv..."
             Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        }

    } catch {
        Write-Host " - Failed to set StartupType for $serviceName. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Set UsoSvc specific registry key for DelayedAutoStart if setting StartupType to Automatic
# This is needed because Set-Service doesn't directly support "Automatic (Delayed Start)"
$usoService = Get-Service -Name UsoSvc -ErrorAction SilentlyContinue
if ($usoService -and $usoService.StartType -eq [System.ServiceProcess.ServiceStartMode]::Automatic) {
    Write-Host " - Setting DelayedAutoStart for UsoSvc..."
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\UsoSvc" -Name "DelayedAutoStart" -Value 1 -ErrorAction Stop
        Write-Host " - DelayedAutoStart set for UsoSvc." -ForegroundColor Green
    } catch {
         Write-Host " - Failed to set DelayedAutoStart for UsoSvc. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}


Write-Host "Finished attempting to re-enable Windows Update services." -ForegroundColor Yellow