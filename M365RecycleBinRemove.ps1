<# 
.SYNOPSIS
  Empty SharePoint/OneDrive Recycle Bin (site or tenant) OR permanently delete Entra ID recycled objects.

.EXAMPLES
  # Site recycle bin
  .\O365RecycleBinRemove.ps1 -SharePointSiteUrl https://contoso.sharepoint.com/sites/HR -All -Force

  # Tenant site collection recycle bin (SECOND STAGE too)
  .\O365RecycleBinRemove.ps1 -TenantAdminUrl https://contoso-admin.sharepoint.com -TenantLevel -Force

  # Permanently delete soft-deleted Entra ID users
  .\O365RecycleBinRemove.ps1 -PurgeDeletedUsers -Force
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [string] $SharePointSiteUrl,
  [string] $TenantAdminUrl,
  [switch] $TenantLevel,
  [switch] $All,                   # delete all items
  [switch] $PurgeDeletedUsers,     # Entra ID deleted users
  [switch] $ForceDeviceCode
)
$ErrorActionPreference = 'Stop'

function Install-ModuleIfMissing {[CmdletBinding()]param([string]$Name,[string]$MinVersion='0.0.0')
  if (-not (Get-Module -ListAvailable -Name $Name)) { Install-Module $Name -MinimumVersion $MinVersion -Scope CurrentUser -Force -AllowClobber }
  Import-Module $Name -MinimumVersion $MinVersion -ErrorAction Stop
}

if ($PurgeDeletedUsers) {
  Install-ModuleIfMissing Microsoft.Graph -MinVersion '2.12.0'
  $scopes = @('Directory.AccessAsUser.All','User.ReadWrite.All')
  if ($ForceDeviceCode){ Connect-MgGraph -Scopes $scopes -UseDeviceCode -NoWelcome } else { Connect-MgGraph -Scopes $scopes -NoWelcome }
  $deleted = Get-MgDirectoryDeletedItemAsUser -All -ErrorAction SilentlyContinue
  if (-not $deleted){ Write-Host "No deleted users." -ForegroundColor Yellow; return }
  foreach ($usr in $deleted) {
    if ($PSCmdlet.ShouldProcess($usr.Id, 'Hard delete user')) {
      Remove-MgDirectoryDeletedItem -DirectoryObjectId $usr.Id -Confirm:$false
    }
  }
  Write-Host "Deleted user recycle bin purged." -ForegroundColor Green
  return
}

# SharePoint / OneDrive
Ensure-Module PnP.PowerShell -MinVersion '2.5.0'
if ($TenantLevel) {
  if (-not $TenantAdminUrl) { throw "-TenantAdminUrl is required with -TenantLevel." }
  Connect-PnPOnline -Url $TenantAdminUrl -Interactive:(!$ForceDeviceCode) -DeviceLogin:$ForceDeviceCode
  $items = Get-PnPTenantRecycleBinItem -RowLimit 5000
  if (-not $items) { Write-Host "Tenant recycle bin empty." -ForegroundColor Yellow; return }
  if ($PSCmdlet.ShouldProcess("Tenant recycle bin", "Purge ($($items.Count)) items")) {
    $items | Clear-PnPTenantRecycleBinItem -Force
    Write-Host "Tenant recycle bin cleared." -ForegroundColor Green
  }
} else {
  if (-not $SharePointSiteUrl) { throw "Provide -SharePointSiteUrl or use -TenantLevel." }
  Connect-PnPOnline -Url $SharePointSiteUrl -Interactive:(!$ForceDeviceCode) -DeviceLogin:$ForceDeviceCode
  if ($All) {
    Get-PnPRecycleBinItem -RowLimit 5000 -SecondStage:$false | Clear-PnPRecycleBinItem -Force
    Get-PnPRecycleBinItem -RowLimit 5000 -SecondStage:$true  | Clear-PnPRecycleBinItem -Force
    Write-Host "Site recycle bin (both stages) cleared." -ForegroundColor Green
  } else {
    Get-PnPRecycleBinItem -RowLimit 5000 | Out-GridView -PassThru | Clear-PnPRecycleBinItem -Force
  }
}
Write-Host "Done." -ForegroundColor Green
Disconnect-PnPOnline -Confirm:$false