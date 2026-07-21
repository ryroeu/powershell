<#
.SYNOPSIS
    Connects to Microsoft Purview compliance PowerShell and/or Exchange Online.
#>

#Requires -Modules ExchangeOnlineManagement

[CmdletBinding()]
param(
    [switch]$Compliance,

    [switch]$ExchangeOnline,

    [switch]$SearchOnly,

    [switch]$UseDeviceAuthentication,

    [string]$UserPrincipalName
)

if (-not ($Compliance -or $ExchangeOnline)) {
    throw 'Specify -Compliance, -ExchangeOnline, or both.'
}
if ($SearchOnly -and -not $Compliance) {
    throw '-SearchOnly requires -Compliance.'
}

if ($Compliance) {
    $parameters = @{ EnableSearchOnlySession = $SearchOnly }
    if ($UserPrincipalName) { $parameters.UserPrincipalName = $UserPrincipalName }
    if ($UseDeviceAuthentication) { $parameters.Device = $true }
    Connect-IPPSSession @parameters | Out-Null
}
if ($ExchangeOnline) {
    $parameters = @{ ShowBanner = $false }
    if ($UserPrincipalName) { $parameters.UserPrincipalName = $UserPrincipalName }
    if ($UseDeviceAuthentication) { $parameters.Device = $true }
    Connect-ExchangeOnline @parameters | Out-Null
}

[pscustomobject]@{
    ComplianceConnected     = $Compliance.IsPresent
    ExchangeOnlineConnected = $ExchangeOnline.IsPresent
    SearchOnly              = $SearchOnly.IsPresent
}
