<#
.SYNOPSIS
    Sets the local Windows computer description.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Description
)

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Set computer description to '$Description'")) {
    Get-CimInstance -ClassName Win32_OperatingSystem |
        Set-CimInstance -Property @{ Description = $Description }
}
