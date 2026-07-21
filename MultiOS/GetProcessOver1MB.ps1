<#
.SYNOPSIS
    Lists processes whose working set exceeds a caller-defined threshold.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [ValidateRange(0, [long]::MaxValue)]
    [long]$MinimumBytes = 1MB
)

Get-Process |
    Where-Object WorkingSet64 -gt $MinimumBytes |
    Sort-Object WorkingSet64 -Descending |
    Select-Object Id, ProcessName,
    @{ Name = 'WorkingSetMB'; Expression = { [Math]::Round($_.WorkingSet64 / 1MB, 2) } },
    CPU, Responding
