<#
.SYNOPSIS
    Adds or removes a Microsoft 365 license with Microsoft Graph.
#>

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Users.Actions

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$UserId,

    [Parameter(Mandatory)]
    [ValidateSet('Add', 'Remove')]
    [string]$Action,

    [Parameter(Mandatory)]
    [string]$SkuPartNumber,

    [string]$TenantId,

    [switch]$UseDeviceCode,

    [switch]$PassThru
)

$connectParameters = @{ Scopes = @('User.ReadWrite.All', 'Directory.ReadWrite.All'); NoWelcome = $true }
if ($TenantId) { $connectParameters.TenantId = $TenantId }
if ($UseDeviceCode) { $connectParameters.UseDeviceCode = $true }
Connect-MgGraph @connectParameters | Out-Null

try {
    $skuMatches = @(Get-MgSubscribedSku -All | Where-Object SkuPartNumber -EQ $SkuPartNumber)
    if ($skuMatches.Count -ne 1) { throw "Expected one subscribed SKU named '$SkuPartNumber'; found $($skuMatches.Count)." }
    $sku = $skuMatches[0]

    if ($PSCmdlet.ShouldProcess($UserId, "$Action license '$SkuPartNumber'")) {
        if ($Action -eq 'Add') {
            Set-MgUserLicense -UserId $UserId -AddLicenses @(@{ SkuId = $sku.SkuId }) -RemoveLicenses @() | Out-Null
        }
        else {
            Set-MgUserLicense -UserId $UserId -AddLicenses @() -RemoveLicenses @($sku.SkuId) | Out-Null
        }
    }

    if ($PassThru) {
        Get-MgUserLicenseDetail -UserId $UserId
    }
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
}
