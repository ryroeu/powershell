<#
.SYNOPSIS
    Reports and optionally enables organization-wide mailbox auditing.
#>

#Requires -Modules ExchangeOnlineManagement

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$UserPrincipalName,

    [switch]$UseDeviceAuthentication,

    [switch]$EnsureEnabled
)

$connectParameters = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParameters.UserPrincipalName = $UserPrincipalName }
if ($UseDeviceAuthentication) { $connectParameters.Device = $true }
Connect-ExchangeOnline @connectParameters

try {
    $organization = Get-OrganizationConfig
    if ($EnsureEnabled -and $organization.AuditDisabled -and
        $PSCmdlet.ShouldProcess($organization.Name, 'Enable organization-wide mailbox auditing')) {
        Set-OrganizationConfig -AuditDisabled:$false
        $organization = Get-OrganizationConfig
    }

    [pscustomobject]@{
        Organization    = $organization.Name
        AuditDisabled   = $organization.AuditDisabled
        DefaultAuditSet = $organization.DefaultAuditSet
    }
}
finally {
    Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}
