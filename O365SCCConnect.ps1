<# 
.SYNOPSIS
  Connect to Microsoft Purview (Compliance/Security) PowerShell and EXO modern endpoints.

.EXAMPLE
  .\O365SCCConnect.ps1 -Compliance -EXO
#>
[CmdletBinding()]
param(
  [switch] $Compliance,
  [switch] $EXO,
  [switch] $SearchOnly,      # for eDiscovery-only sessions
  [switch] $ForceDeviceCode
)
$ErrorActionPreference = 'Stop'

function Ensure-Module {
  param([string]$Name,[string]$MinVersion='0.0.0')
  if (-not (Get-Module -ListAvailable -Name $Name)) {
    Install-Module $Name -MinimumVersion $MinVersion -Scope CurrentUser -Force -AllowClobber
  }
  Import-Module $Name -MinimumVersion $MinVersion -ErrorAction Stop
}

Ensure-Module ExchangeOnlineManagement -MinVersion '3.4.0'

if ($Compliance) {
  if ($ForceDeviceCode) {
    Connect-IPPSSession -UseDeviceAuthentication -EnableSearchOnlySession:$SearchOnly | Out-Null
  } else {
    Connect-IPPSSession -EnableSearchOnlySession:$SearchOnly | Out-Null
  }
  Write-Host "Connected to Purview (Compliance & Security)." -ForegroundColor Green
}

if ($EXO) {
  if ($ForceDeviceCode) {
    Connect-ExchangeOnline -UseDeviceAuthentication | Out-Null
  } else {
    Connect-ExchangeOnline | Out-Null
  }
  Write-Host "Connected to Exchange Online." -ForegroundColor Green
}
Write-Host "Done." -ForegroundColor Green