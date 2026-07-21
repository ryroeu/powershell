<#
.SYNOPSIS
    Disables hibernation on Windows.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

if ($PSCmdlet.ShouldProcess('Local computer', 'Disable hibernation')) {
    & "$env:SystemRoot\System32\powercfg.exe" /hibernate off
    if ($LASTEXITCODE -ne 0) {
        throw "powercfg.exe failed with exit code $LASTEXITCODE."
    }
}
