<#
.SYNOPSIS
    Opens an interactive Microsoft Graph session.
#>

#Requires -Modules Microsoft.Graph.Authentication

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,

    [string[]]$Scopes = @('User.ReadWrite.All', 'Directory.ReadWrite.All'),

    [switch]$UseDeviceCode
)

$parameters = @{ TenantId = $TenantId; Scopes = $Scopes; NoWelcome = $true }
if ($UseDeviceCode) { $parameters.UseDeviceCode = $true }
Connect-MgGraph @parameters
Get-MgContext
