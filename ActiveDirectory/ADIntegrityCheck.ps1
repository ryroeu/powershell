<#
.SYNOPSIS
    Runs an NTDS semantic database analysis on a domain controller.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Stop AD DS and run semantic database analysis')) {
    Stop-Service -Name NTDS -Force -ErrorAction Stop
    try {
        & ntdsutil.exe 'activate instance ntds' 'semantic database analysis' 'verbose on' 'go' quit quit
        if ($LASTEXITCODE -ne 0) { throw "ntdsutil.exe failed with exit code $LASTEXITCODE." }
    }
    finally {
        Start-Service -Name NTDS -ErrorAction Stop
    }
}
