<#
.SYNOPSIS
    Samples normalized CPU usage for selected processes.
#>

#Requires -Version 7.0

[CmdletBinding(DefaultParameterSetName = 'ByName')]
param(
    [Parameter(Mandatory, ParameterSetName = 'ByName')]
    [SupportsWildcards()]
    [string]$ProcessName,

    [Parameter(Mandatory, ParameterSetName = 'ById')]
    [ValidateRange(0, [int]::MaxValue)]
    [int[]]$ProcessId,

    [ValidateRange(0.1, 60)]
    [double]$IntervalSeconds = 1
)

$processes = if ($PSCmdlet.ParameterSetName -eq 'ById') {
    @(Get-Process -Id $ProcessId -ErrorAction Stop)
}
else {
    @(Get-Process | Where-Object ProcessName -Like $ProcessName)
}
if (-not $processes) { throw 'No matching processes were found.' }

$firstSample = @{}
foreach ($process in $processes) {
    try { $firstSample[$process.Id] = $process.TotalProcessorTime } catch { Write-Verbose "Could not sample process $($process.Id): $($_.Exception.Message)" }
}

Start-Sleep -Milliseconds ([int]($IntervalSeconds * 1000))
$logicalProcessorCount = [Environment]::ProcessorCount

foreach ($id in $firstSample.Keys) {
    $process = Get-Process -Id $id -ErrorAction SilentlyContinue
    if (-not $process) { continue }
    try {
        $cpuDelta = $process.TotalProcessorTime - $firstSample[$id]
        $normalizedPercent = ($cpuDelta.TotalSeconds / ($IntervalSeconds * $logicalProcessorCount)) * 100
        [pscustomobject]@{
            Id                    = $process.Id
            ProcessName           = $process.ProcessName
            CPUPercent            = [Math]::Round([Math]::Max(0, $normalizedPercent), 2)
            IntervalSeconds       = $IntervalSeconds
            LogicalProcessorCount = $logicalProcessorCount
        }
    }
    catch {
        Write-Verbose "Could not complete the sample for process ${id}: $($_.Exception.Message)"
    }
}
