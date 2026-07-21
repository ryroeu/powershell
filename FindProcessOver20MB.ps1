<#
.SYNOPSIS
    Returns processes whose working set exceeds a threshold.
#>

[CmdletBinding()]
param(
    [ValidateRange(0, [double]::MaxValue)]
    [double]$MinimumMegabytes = 20
)

Get-Process |
    Where-Object WorkingSet64 -GT ($MinimumMegabytes * 1MB) |
    Select-Object Name, Id, @{Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } }
