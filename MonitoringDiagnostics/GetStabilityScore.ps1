<#
.SYNOPSIS
    Summarizes the Windows Reliability Monitor stability index.
#>

[CmdletBinding()]
param(
    [ValidateRange(1, 10000)]
    [int]$Count = 672
)

if (-not $IsWindows) { throw 'This script requires Windows.' }
$metrics = @(Get-CimInstance -ClassName Win32_ReliabilityStabilityMetrics -ErrorAction Stop |
        Sort-Object TimeGenerated -Descending |
        Select-Object -First $Count)
if (-not $metrics) { throw 'No reliability stability metrics were returned.' }

$statistics = $metrics | Measure-Object -Property SystemStabilityIndex -Average -Maximum -Minimum
$latest = $metrics[0]
[pscustomobject]@{
    SampleCount = $metrics.Count
    Minimum     = [Math]::Round($statistics.Minimum, 2)
    Average     = [Math]::Round($statistics.Average, 2)
    Maximum     = [Math]::Round($statistics.Maximum, 2)
    Latest      = $latest.SystemStabilityIndex
    LatestDate  = [datetime]$latest.TimeGenerated
}
