<#
.SYNOPSIS
    Exports SharePoint Online users and group memberships with PnP.PowerShell.
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

    [string]$OutputPath
)

$parameters = @{ Url = $SiteUrl.AbsoluteUri; Interactive = $true; ClientId = $ClientId }
if ($Tenant) { $parameters.Tenant = $Tenant }
Connect-PnPOnline @parameters

try {
    $results = foreach ($group in Get-PnPGroup) {
        foreach ($member in Get-PnPGroupMember -Group $group) {
            [pscustomobject]@{
                SiteUrl       = $SiteUrl.AbsoluteUri
                GroupName     = $group.Title
                DisplayName   = $member.Title
                LoginName     = $member.LoginName
                Email         = $member.Email
                PrincipalType = $member.PrincipalType
            }
        }
    }

    if ($OutputPath) {
        $results | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8NoBOM
    }
    $results
}
finally {
    Disconnect-PnPOnline -ErrorAction SilentlyContinue
}
