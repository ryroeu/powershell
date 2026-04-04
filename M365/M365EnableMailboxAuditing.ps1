<# 
.SYNOPSIS
  Verify/enable mailbox auditing using ExchangeOnlineManagement v3+ (auditing is on by default).

.EXAMPLE
  .\O365EnableMailboxAuditing.ps1 -EnsureEnabled
#>
[CmdletBinding()]
param(
  [switch] $EnsureEnabled,     # set org auditing on if disabled
  [switch] $ReportOnly,        # show current values only
  [switch] $ForceDeviceCode
)
$ErrorActionPreference = 'Stop'

function Install-ModuleIfMissing {
  param([string]$Name,[string]$MinVersion='0.0.0')
  if (-not (Get-Module -ListAvailable -Name $Name)) {
    Install-Module $Name -MinimumVersion $MinVersion -Scope CurrentUser -Force -AllowClobber
  }
  Import-Module $Name -MinimumVersion $MinVersion -ErrorAction Stop
}

Install-ModuleIfMissing ExchangeOnlineManagement -MinVersion '3.4.0'

if ($ForceDeviceCode) {
  Connect-ExchangeOnline -UseDeviceAuthentication | Out-Null
} else {
  Connect-ExchangeOnline | Out-Null
}

$org = Get-OrganizationConfig
Write-Host ("AuditDisabled: {0}" -f $org.AuditDisabled) -ForegroundColor Cyan
Write-Host ("DefaultAuditSet (current build default): {0}" -f ($org.DefaultAuditSet -join ',')) -ForegroundColor Cyan

if ($ReportOnly) { return }

if ($EnsureEnabled -and $org.AuditDisabled) {
  Write-Host "Enabling org-wide mailbox auditing..." -ForegroundColor Yellow
  Set-OrganizationConfig -AuditDisabled:$false
  $org = Get-OrganizationConfig
  Write-Host ("AuditDisabled: {0}" -f $org.AuditDisabled) -ForegroundColor Green
}

Disconnect-ExchangeOnline -Confirm:$false | Out-Null
