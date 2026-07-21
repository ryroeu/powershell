<#
.SYNOPSIS
    Changes file extensions without converting file contents.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$Path = $PWD,

    [Parameter(Mandatory)]
    [ValidatePattern('^\.?[^.\\/]+$')]
    [string]$FromExtension,

    [Parameter(Mandatory)]
    [ValidatePattern('^\.?[^.\\/]+$')]
    [string]$ToExtension
)

$from = if ($FromExtension.StartsWith('.')) { $FromExtension } else { ".$FromExtension" }
$to = if ($ToExtension.StartsWith('.')) { $ToExtension } else { ".$ToExtension" }

Get-ChildItem -LiteralPath $Path -File |
    Where-Object Extension -EQ $from |
    Rename-Item -NewName { [IO.Path]::ChangeExtension($_.Name, $to) } -WhatIf:$WhatIfPreference
