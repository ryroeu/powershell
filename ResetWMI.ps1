<#
.SYNOPSIS
    Verifies, salvages, or resets the Windows Management Instrumentation repository.
.DESCRIPTION
    Verification is non-destructive. Salvage rebuilds an inconsistent repository while preserving readable data.
    Reset returns the repository to its initial operating-system state and should be a last resort.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateSet('Verify', 'Salvage', 'Reset')]
    [string]$Action = 'Verify'
)

$winmgmt = Join-Path $env:SystemRoot 'System32\wbem\winmgmt.exe'
if (-not (Test-Path -LiteralPath $winmgmt)) {
    throw "winmgmt.exe was not found at '$winmgmt'."
}

$argument = switch ($Action) {
    'Verify' { '/verifyrepository' }
    'Salvage' { '/salvagerepository' }
    'Reset' { '/resetrepository' }
}
$impact = if ($Action -eq 'Verify') { 'Verify WMI repository consistency' } else { "$Action WMI repository" }

if ($PSCmdlet.ShouldProcess('Local WMI repository', $impact)) {
    $output = & $winmgmt $argument 2>&1
    $exitCode = $LASTEXITCODE
    [pscustomobject]@{
        Action   = $Action
        ExitCode = $exitCode
        Output   = $output -join [Environment]::NewLine
    }
    if ($exitCode -ne 0) {
        throw "winmgmt.exe $argument failed with exit code $exitCode."
    }
}
