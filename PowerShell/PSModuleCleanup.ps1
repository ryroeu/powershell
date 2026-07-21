<#
.SYNOPSIS
    Removes superseded versions of modules installed through PSResourceGet.
#>

#Requires -Version 7.4

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string[]]$Name = @('*'),

    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser'
)

if (-not (Get-Command Get-InstalledPSResource -ErrorAction SilentlyContinue)) {
    throw 'Microsoft.PowerShell.PSResourceGet is required.'
}

$installed = @(Get-InstalledPSResource -Name $Name -Scope $Scope)
foreach ($group in $installed | Group-Object Name) {
    $versions = @($group.Group | Sort-Object Version -Descending)
    if ($versions.Count -le 1) { continue }

    $latest = $versions[0]
    foreach ($oldResource in $versions | Select-Object -Skip 1) {
        $target = "$($oldResource.Name) $($oldResource.Version) ($Scope)"
        if ($PSCmdlet.ShouldProcess($target, "Uninstall superseded version; keep $($latest.Version)")) {
            Uninstall-PSResource -Name $oldResource.Name -Version $oldResource.Version -Scope $Scope -ErrorAction Stop
        }
    }
}
