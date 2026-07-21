<#
.SYNOPSIS
    Scans for or installs Windows updates with PSWindowsUpdate.
.EXAMPLE
    ./WindowsUpdate.ps1
.EXAMPLE
    ./WindowsUpdate.ps1 -Install -AcceptAll -AutoReboot
#>

#Requires -RunAsAdministrator
#Requires -Modules PSWindowsUpdate

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [switch]$Install,

    [switch]$MicrosoftUpdate,

    [switch]$AcceptAll,

    [switch]$AutoReboot
)

if (-not $IsWindows) {
    throw 'This script requires Windows.'
}
if (($AcceptAll -or $AutoReboot) -and -not $Install) {
    throw '-AcceptAll and -AutoReboot are valid only with -Install.'
}

if ($MicrosoftUpdate -and $PSCmdlet.ShouldProcess('Microsoft Update service', 'Register update service')) {
    Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
}

if (-not $Install) {
    Get-WindowsUpdate -MicrosoftUpdate:$MicrosoftUpdate
    return
}

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Install available Windows updates')) {
    Get-WindowsUpdate -MicrosoftUpdate:$MicrosoftUpdate -Install -AcceptAll:$AcceptAll -AutoReboot:$AutoReboot
}
