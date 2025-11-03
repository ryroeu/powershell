<# 
.SYNOPSIS
  Add or remove Microsoft 365 licenses for a user using Microsoft Graph PowerShell.

.EXAMPLE
  .\O365AddLicense.ps1 -UserId alice@contoso.com -SkuPartNumber ENTERPRISEPACK -Action Add

.EXAMPLE
  .\O365AddLicense.ps1 -UserId alice@contoso.com -SkuPartNumber ENTERPRISEPACK -Action Remove
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $UserId,                      # UPN or GUID
  [Parameter(Mandatory)] [ValidateSet('Add','Remove')] [string] $Action,
  [Parameter(Mandatory)] [string] $SkuPartNumber,               # e.g. ENTERPRISEPACK, O365_BUSINESS, SPE_E5 etc.
  [switch] $ForceDeviceCode,                                    # use device code auth
  [switch] $VerboseOutput
)

$ErrorActionPreference = 'Stop'

function Install-RequiredModule {
  param([string]$Name,[string]$MinVersion='0.0.0')
  if (-not (Get-Module -ListAvailable -Name $Name)) {
    Write-Host "Installing module $Name..." -ForegroundColor Yellow
    Install-Module $Name -MinimumVersion $MinVersion -Scope CurrentUser -Force -AllowClobber
  }
  Import-Module $Name -MinimumVersion $MinVersion -ErrorAction Stop
}

Install-RequiredModule Microsoft.Graph -MinVersion '2.12.0'

$scopes = @('User.ReadWrite.All','Directory.ReadWrite.All')
if ($ForceDeviceCode) {
  Connect-MgGraph -Scopes $scopes -UseDeviceCode -NoWelcome | Out-Null
} else {
  Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null
}
Select-MgProfile -Name beta

# Resolve SKU
$sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq $SkuPartNumber
if (-not $sku) { throw "SkuPartNumber '$SkuPartNumber' not found in your tenant." }

# Explicit empty arrays avoid parameter binding quirks on some Graph versions
$add  = @()
$rem  = @()

switch ($Action) {
  'Add'    { $add = @(@{ SkuId = $sku.SkuId }) }
  'Remove' { $rem = @($sku.SkuId) }
}

Write-Host "$Action license '$SkuPartNumber' for $UserId..." -ForegroundColor Cyan
Set-MgUserLicense -UserId $UserId -AddLicenses $add -RemoveLicenses $rem

if ($VerboseOutput) {
  Get-MgUserLicenseDetail -UserId $UserId | Select-Object SkuPartNumber,ServicePlans | Format-List
}

Write-Host "Done." -ForegroundColor Green
Disconnect-MgGraph -Confirm:$false