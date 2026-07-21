<#
.SYNOPSIS
    Releases IPv6 DHCP leases on Windows adapters.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string[]]$InterfaceAlias
)

if (-not $IsWindows) { throw 'This script requires Windows.' }
$targets = if ($InterfaceAlias) { $InterfaceAlias } else { @('*') }
foreach ($target in $targets) {
    if ($PSCmdlet.ShouldProcess($target, 'Release IPv6 DHCP lease')) {
        $arguments = if ($target -eq '*') { @('/release6') } else { @('/release6', $target) }
        & "$env:SystemRoot\System32\ipconfig.exe" @arguments
        if ($LASTEXITCODE -ne 0) { throw "ipconfig failed with exit code $LASTEXITCODE for '$target'." }
    }
}
