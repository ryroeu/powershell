<#
.SYNOPSIS
    Restarts Windows into the advanced startup options menu.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateRange(0, 3600)]
    [int]$DelaySeconds = 0
)

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Restart into advanced startup options')) {
    & "$env:SystemRoot\System32\shutdown.exe" /r /o /t $DelaySeconds
    if ($LASTEXITCODE -ne 0) { throw "shutdown.exe failed with exit code $LASTEXITCODE." }
}
