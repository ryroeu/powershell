<#
.SYNOPSIS
    Renews IPv4 DHCP leases on Windows adapters.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string[]]$InterfaceAlias
)

if (-not $IsWindows) { throw 'This script requires Windows.' }
$targets = if ($InterfaceAlias) { $InterfaceAlias } else { @('*') }
foreach ($target in $targets) {
    if ($PSCmdlet.ShouldProcess($target, 'Renew IPv4 DHCP lease')) {
        $arguments = if ($target -eq '*') { @('/renew') } else { @('/renew', $target) }
        & "$env:SystemRoot\System32\ipconfig.exe" @arguments
        if ($LASTEXITCODE -ne 0) { throw "ipconfig failed with exit code $LASTEXITCODE for '$target'." }
    }
}
