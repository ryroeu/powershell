<#
.SYNOPSIS
    Backs up and optionally clears local Group Policy registry caches before refreshing policy.
.DESCRIPTION
    Clearing these policy keys is disruptive. Backups are exported before removal and -ResetPolicyCache
    must be specified explicitly. The script no longer changes DNS server addresses.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$BackupDirectory = (Join-Path $env:SystemDrive 'PolicyRegistryBackup'),

    [switch]$ResetPolicyCache
)

$entries = @(
    @{ NativePath = 'HKLM\Software\Policies\Microsoft'; ProviderPath = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft'; FileName = 'HKLM_Policies_Microsoft.reg' },
    @{ NativePath = 'HKCU\Software\Policies\Microsoft'; ProviderPath = 'Registry::HKEY_CURRENT_USER\Software\Policies\Microsoft'; FileName = 'HKCU_Policies_Microsoft.reg' },
    @{ NativePath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects'; ProviderPath = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects'; FileName = 'HKCU_GroupPolicyObjects.reg' },
    @{ NativePath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies'; ProviderPath = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies'; FileName = 'HKCU_CurrentVersion_Policies.reg' }
)

$null = New-Item -ItemType Directory -Path $BackupDirectory -Force
foreach ($entry in $entries) {
    if (-not (Test-Path -LiteralPath $entry.ProviderPath)) { continue }
    $backupPath = Join-Path $BackupDirectory $entry.FileName
    & "$env:SystemRoot\System32\reg.exe" export $entry.NativePath $backupPath /y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to export '$($entry.NativePath)'." }

    if ($ResetPolicyCache -and $PSCmdlet.ShouldProcess($entry.ProviderPath, "Remove policy registry key after backup to '$backupPath'")) {
        Remove-Item -LiteralPath $entry.ProviderPath -Recurse -Force
    }
}

if ($PSCmdlet.ShouldProcess('Local computer', 'Refresh Group Policy')) {
    & "$env:SystemRoot\System32\gpupdate.exe" /force
    if ($LASTEXITCODE -ne 0) { throw "gpupdate.exe failed with exit code $LASTEXITCODE." }
}
