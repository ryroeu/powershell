<#
.SYNOPSIS
    Retrieves SharePoint Online site users with PnP.PowerShell.
#>

#Requires -Version 7.4
#Requires -Modules PnP.PowerShell

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [uri]$SiteUrl,

    [Parameter(Mandatory)]
    [string]$ClientId,

    [string]$Tenant,

    [string]$LoginName,

    [string]$OutputPath
)

$connectParameters = @{ Url = $SiteUrl.AbsoluteUri; Interactive = $true; ClientId = $ClientId }
if ($Tenant) { $connectParameters.Tenant = $Tenant }
Connect-PnPOnline @connectParameters

try {
    $users = Get-PnPUser
    if ($LoginName) {
        $users = $users | Where-Object { $_.LoginName -eq $LoginName -or $_.Email -eq $LoginName }
    }

    $users = $users | Select-Object Id, Title, Email, LoginName, PrincipalType, IsSiteAdmin
    if ($OutputPath) {
        $users | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8NoBOM
        Get-Item -LiteralPath $OutputPath
    }
    else {
        $users
    }
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
