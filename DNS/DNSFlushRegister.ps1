<#
.SYNOPSIS
    Clears the Windows DNS client cache and registers DNS records.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

if (-not $IsWindows) { throw 'This script requires Windows.' }
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Clear the DNS client cache and register DNS records')) {
    Clear-DnsClientCache
    Register-DnsClient
}
