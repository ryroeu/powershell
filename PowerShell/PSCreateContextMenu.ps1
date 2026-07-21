<#
.SYNOPSIS
    Adds a Run with PowerShell 7 (Administrator) context-menu command for .ps1 files.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$PowerShellPath = (Join-Path $PSHOME 'pwsh.exe')
)

if (-not (Test-Path -LiteralPath $PowerShellPath -PathType Leaf)) {
    throw "PowerShell executable not found at '$PowerShellPath'."
}

$verbPath = 'Registry::HKEY_CLASSES_ROOT\Microsoft.PowerShellScript.1\Shell\RunWithPowerShell7Admin'
$commandPath = Join-Path $verbPath 'Command'
$escapedPowerShellPath = $PowerShellPath.Replace("'", "''")
$command = '"{0}" -NoProfile -Command "Start-Process -FilePath ''{0}'' -ArgumentList ''-NoProfile -File \"%1\"'' -Verb RunAs"' -f $escapedPowerShellPath

if ($PSCmdlet.ShouldProcess($verbPath, 'Create elevated PowerShell 7 context-menu command')) {
    $null = New-Item -Path $commandPath -Force
    Set-Item -LiteralPath $verbPath -Value 'Run with PowerShell 7 (Administrator)'
    Set-Item -LiteralPath $commandPath -Value $command
}
