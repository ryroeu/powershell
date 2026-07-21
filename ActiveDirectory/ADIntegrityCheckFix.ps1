<#
.SYNOPSIS
    Runs NTDS semantic database analysis with fixup on a domain controller.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Stop AD DS and run destructive semantic database fixup')) {
    Stop-Service -Name NTDS -Force -ErrorAction Stop
    try {
        & ntdsutil.exe 'activate instance ntds' 'semantic database analysis' 'verbose on' 'go fixup' quit quit
        if ($LASTEXITCODE -ne 0) { throw "ntdsutil.exe failed with exit code $LASTEXITCODE." }
    }
    finally {
        Start-Service -Name NTDS -ErrorAction Stop
    }
}
