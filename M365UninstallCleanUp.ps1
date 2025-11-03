<# 
.SYNOPSIS
  Post-uninstall cleanup for Microsoft 365 Apps leftovers.

.EXAMPLE
  .\O365UninstallCleanUp.ps1
#>
[CmdletBinding()]
param(
  [switch] $Aggressive   # removes extra cached folders if present
)
$ErrorActionPreference = 'Stop'

# Stop services if any remain
$services = 'ClickToRunSvc','OfficeSvc','sftlist','osppsvc'
foreach ($svc in $services) {
  $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
  if ($s -and $s.Status -ne 'Stopped') {
    Write-Host "Stopping service $svc..." -ForegroundColor Yellow
    Stop-Service $svc -Force -ErrorAction SilentlyContinue
    Set-Service  $svc -StartupType Disabled -ErrorAction SilentlyContinue
  }
}

# Scheduled tasks (old updater tasks)
$tasks = @(
  '\Microsoft\Office\Office ClickToRun Service Monitor',
  '\Microsoft\Office\OfficeTelemetryAgentLogOn',
  '\Microsoft\Office\OfficeTelemetryAgentFallBack'
)
foreach ($t in $tasks) {
  if (Get-ScheduledTask -TaskPath ($t.Substring(0,$t.LastIndexOf('\')+1)) -TaskName ($t.Split('\')[-1]) -ErrorAction SilentlyContinue) {
    Write-Host "Deleting scheduled task $t" -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskPath ($t.Substring(0,$t.LastIndexOf('\')+1)) -TaskName ($t.Split('\')[-1]) -Confirm:$false
  }
}

# Start menu and program files vestiges
$paths = @(
  "$env:ProgramFiles\Common Files\microsoft shared\ClickToRun",
  "$env:ProgramFiles\Microsoft Office",
  "$env:ProgramFiles(x86)\Microsoft Office",
  "$env:LOCALAPPDATA\Microsoft\Office",
  "$env:APPDATA\Microsoft\Templates",
  "$env:ProgramData\Microsoft\Office",
  "$env:ProgramData\Microsoft\ClickToRun"
)
if ($Aggressive) {
  $paths += @("$env:LOCALAPPDATA\Microsoft\OneDrive\Update","$env:LOCALAPPDATA\Microsoft\Teams\current")
}
foreach ($p in $paths) {
  if (Test-Path $p) {
    Write-Host "Removing $p" -ForegroundColor Yellow
    Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# Clear ARP stale entries (non-destructive, only ClickToRun if present)
$reg = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
Get-ChildItem $reg -ErrorAction SilentlyContinue |
  ForEach-Object { Get-ItemProperty $_.PsPath } |
  Where-Object { $_.DisplayName -like '*Click-to-Run*' -or $_.DisplayName -like '*Microsoft 365*' } |
  ForEach-Object {
    try {
      Remove-Item $_.PSPath -Recurse -Force
      Write-Host "Cleaned uninstall key: $($_.DisplayName)" -ForegroundColor Green
    } catch { }
  }

Write-Host "Cleanup completed." -ForegroundColor Green
