<#
.SYNOPSIS
    Removes superseded versions of modules installed by PowerShellGet.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string[]]$Name = '*'
)

$installed = @(Get-InstalledModule -Name $Name -AllVersions -ErrorAction SilentlyContinue)
foreach ($group in $installed | Group-Object Name) {
    $versions = @($group.Group | Sort-Object Version -Descending)
    if ($versions.Count -le 1) {
        Write-Verbose "Only one installed version of '$($group.Name)' was found."
        continue
    }

    $latest = $versions[0]
    foreach ($oldModule in $versions | Select-Object -Skip 1) {
        $target = "$($oldModule.Name) $($oldModule.Version)"
        if ($PSCmdlet.ShouldProcess($target, "Uninstall superseded module; keeping $($latest.Version)")) {
            Uninstall-Module -Name $oldModule.Name -RequiredVersion $oldModule.Version -Force -ErrorAction Stop
        }
    }
}
