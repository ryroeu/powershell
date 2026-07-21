<#
.SYNOPSIS
    Resets supported Windows Update caches and restarts their services.
.DESCRIPTION
    Stops Windows Update services, moves SoftwareDistribution and Catroot2 to timestamped backup
    folders, and restores service state. Network and WSUS identity resets are opt-in.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [switch]$ClearBitsQueue,

    [switch]$ResetWinsock,

    [switch]$ResetWinHttpProxy,

    [switch]$RemoveWsusClientIdentity,

    [switch]$Scan
)

if (-not $IsWindows) { throw 'This script requires Windows.' }

$serviceNames = @('BITS', 'wuauserv', 'cryptSvc')
$serviceStates = @{}
$backups = [Collections.Generic.List[object]]::new()
$timestamp = Get-Date -Format 'yyyyMMddHHmmss'

try {
    foreach ($serviceName in $serviceNames) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if (-not $service) { continue }
        $serviceStates[$serviceName] = $service.Status
        if ($service.Status -ne 'Stopped' -and $PSCmdlet.ShouldProcess($serviceName, 'Stop service')) {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
        }
    }

    if ($ClearBitsQueue) {
        if (-not (Get-Command Get-BitsTransfer -ErrorAction SilentlyContinue)) {
            throw 'The BitsTransfer module is required for -ClearBitsQueue.'
        }
        $jobs = @(Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue)
        if ($jobs -and $PSCmdlet.ShouldProcess("$($jobs.Count) BITS job(s)", 'Remove')) {
            $jobs | Remove-BitsTransfer -Confirm:$false
        }
    }

    foreach ($cachePath in @(
            (Join-Path $env:SystemRoot 'SoftwareDistribution'),
            (Join-Path $env:SystemRoot 'System32\catroot2')
        )) {
        if (-not (Test-Path -LiteralPath $cachePath)) { continue }
        $backupPath = "$cachePath.$timestamp.bak"
        if ($PSCmdlet.ShouldProcess($cachePath, "Move to '$backupPath'")) {
            Move-Item -LiteralPath $cachePath -Destination $backupPath -ErrorAction Stop
            $backups.Add([pscustomobject]@{ OriginalPath = $cachePath; BackupPath = $backupPath })
        }
    }

    if ($RemoveWsusClientIdentity) {
        $windowsUpdatePath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate'
        foreach ($valueName in 'AccountDomainSid', 'PingID', 'SusClientId', 'SusClientIdValidation') {
            if ($PSCmdlet.ShouldProcess("$windowsUpdatePath :: $valueName", 'Remove WSUS client identity value')) {
                Remove-ItemProperty -Path $windowsUpdatePath -Name $valueName -ErrorAction SilentlyContinue
            }
        }
    }

    if ($ResetWinsock -and $PSCmdlet.ShouldProcess('Winsock catalog', 'Reset')) {
        & "$env:SystemRoot\System32\netsh.exe" winsock reset
        if ($LASTEXITCODE -ne 0) { throw "Winsock reset failed with exit code $LASTEXITCODE." }
    }
    if ($ResetWinHttpProxy -and $PSCmdlet.ShouldProcess('WinHTTP proxy', 'Reset')) {
        & "$env:SystemRoot\System32\netsh.exe" winhttp reset proxy
        if ($LASTEXITCODE -ne 0) { throw "WinHTTP proxy reset failed with exit code $LASTEXITCODE." }
    }
}
finally {
    foreach ($serviceName in $serviceNames) {
        if (-not $serviceStates.ContainsKey($serviceName)) { continue }
        if ($serviceStates[$serviceName] -eq 'Running' -and $PSCmdlet.ShouldProcess($serviceName, 'Restore running state')) {
            Start-Service -Name $serviceName -ErrorAction SilentlyContinue
        }
    }
}

if ($Scan) {
    if (-not (Get-Command Get-WindowsUpdate -ErrorAction SilentlyContinue)) {
        throw 'Install/import the PSWindowsUpdate module before using -Scan.'
    }
    Get-WindowsUpdate
}

[pscustomobject]@{
    ComputerName       = $env:COMPUTERNAME
    CacheBackups       = $backups.ToArray()
    WinsockReset       = $ResetWinsock.IsPresent
    WinHttpProxyReset  = $ResetWinHttpProxy.IsPresent
    RestartRecommended = $ResetWinsock.IsPresent
}
