<#
.SYNOPSIS
    Tests and optionally repairs the local computer's domain secure channel.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$Server,

    [pscredential]$Credential,

    [switch]$Repair
)

$parameters = @{}
if ($Server) { $parameters.Server = $Server }
if ($Credential) { $parameters.Credential = $Credential }
if ($Repair) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Repair domain secure channel')) {
        Test-ComputerSecureChannel @parameters -Repair -Verbose
    }
}
else {
    Test-ComputerSecureChannel @parameters -Verbose
}
