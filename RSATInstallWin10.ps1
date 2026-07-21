<#
.SYNOPSIS
    Installs selected RSAT Windows capabilities on Windows 10 or Windows 11.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string[]]$Name = @('Rsat.*')
)

if (-not $IsWindows) { throw 'This script requires Windows.' }

$capabilities = Get-WindowsCapability -Online |
    Where-Object {
        $capabilityName = $_.Name
        $_.State -eq 'NotPresent' -and
        @($Name | Where-Object { $capabilityName -like $_ }).Count -gt 0
    }

foreach ($capability in $capabilities) {
    if ($PSCmdlet.ShouldProcess($capability.Name, 'Install Windows capability')) {
        Add-WindowsCapability -Online -Name $capability.Name
    }
}
