<#
.SYNOPSIS
    Applies a Windows product key to an offline Windows image.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9]{5}(?:-[A-Za-z0-9]{5}){4}$')]
    [string]$ProductKey
)

if ($PSCmdlet.ShouldProcess($Path, 'Set Windows product key')) {
    Set-WindowsProductKey -Path $Path -ProductKey $ProductKey
}
