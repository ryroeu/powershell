#Requires -Modules Microsoft.Graph.Authentication

<#
.SYNOPSIS
    Imports a PFX certificate and uses it for Microsoft Graph application authentication.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$FilePath,

    [Parameter(Mandatory)]
    [securestring]$Password,

    [Parameter(Mandatory)]
    [string]$ClientId,

    [Parameter(Mandatory)]
    [string]$TenantId
)

$certificate = Get-PfxCertificate -LiteralPath $FilePath -Password $Password -NoPromptForPassword

Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -Certificate $certificate -NoWelcome
Get-MgContext
