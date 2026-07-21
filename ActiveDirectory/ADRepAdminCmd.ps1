<#
.SYNOPSIS
    Runs a selected Repadmin diagnostic or synchronization operation.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateSet('Kcc', 'Queue', 'ReplSummary', 'ShowBackup', 'ShowRepl', 'ShowUtdVec', 'SyncAll')]
    [string]$Operation = 'ReplSummary',

    [string]$DomainController = '*',

    [pscredential]$Credential
)

$arguments = switch ($Operation) {
    'Kcc' { @('/kcc', $DomainController) }
    'Queue' { @('/queue', $DomainController) }
    'ReplSummary' { @('/replsummary', $DomainController) }
    'ShowBackup' { @('/showbackup', $DomainController) }
    'ShowRepl' { @('/showrepl', $DomainController) }
    'ShowUtdVec' { @('/showutdvec', $DomainController, '*', '/latency') }
    'SyncAll' { @('/syncall', $DomainController, '/A', '/e', '/P') }
}

if ($Credential) {
    $plainPassword = $Credential.GetNetworkCredential().Password
    $arguments += "/u:$($Credential.UserName)", "/pw:$plainPassword"
}

try {
    $isStateChanging = $Operation -in 'Kcc', 'SyncAll'
    if (-not $isStateChanging -or $PSCmdlet.ShouldProcess($DomainController, "Run Repadmin $Operation")) {
        & repadmin.exe @arguments
        if ($LASTEXITCODE -ne 0) { throw "repadmin.exe failed with exit code $LASTEXITCODE." }
    }
}
finally {
    $plainPassword = $null
}
