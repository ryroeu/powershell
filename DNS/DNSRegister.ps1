<#
.SYNOPSIS
    Registers this Windows computer's DNS client records.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

if (-not $IsWindows) { throw 'This script requires Windows.' }
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Register DNS client records')) {
    Register-DnsClient
}
