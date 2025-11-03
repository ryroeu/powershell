<# 
.SYNOPSIS
  Measure local network interface bandwidth (Rx/Tx Mbps) by sampling adapter statistics.

.DESCRIPTION
  Uses Get-NetAdapterStatistics to read byte counters twice (or multiple times),
  computes deltas over the sampling interval, and reports average/peak Mbps.
  Works on Windows PowerShell 5.1 and PowerShell 7+.

.PARAMETER InterfaceName
  One or more adapter names to include (wildcards allowed). Defaults to all up/connected adapters.

.PARAMETER DurationSeconds
  Total sampling duration. Default: 10 seconds.

.PARAMETER IntervalSeconds
  Interval between samples. Default: 1 second.

.PARAMETER IncludeVirtual
  Include Hyper-V vEthernet, loopback, VPN/TAP, and other virtual/hidden adapters.

.PARAMETER Timeline
  Also return a per-interval timeline (one row per sample per adapter).

.PARAMETER As
  Output mode: Table (default), Json, or Csv.

.PARAMETER OutCsv
  If set, exports the main summary to CSV.

.EXAMPLES
  # Quick 10 second average for all physical adapters
  .\GetNetBandwidth.ps1

  # Focus on a specific interface for 30s, show timeline and export CSV
  .\GetNetBandwidth.ps1 -InterfaceName "Ethernet 2" -DurationSeconds 30 -Timeline -OutCsv .\bandwidth.csv

  # Show JSON for all active adapters, 5Hz sampling for 15s
  .\GetNetBandwidth.ps1 -DurationSeconds 15 -IntervalSeconds 0.2 -As Json
#>

[CmdletBinding()]
param(
  [string[]] $InterfaceName,
  [double]   $DurationSeconds = 10,
  [double]   $IntervalSeconds = 1,
  [switch]   $IncludeVirtual,
  [switch]   $Timeline,
  [ValidateSet('Table','Json','Csv')] [string] $As = 'Table',
  [string]   $OutCsv
)

$ErrorActionPreference = 'Stop'

function Get-Adapters {
  $adapters = Get-NetAdapter -Physical:$(!$IncludeVirtual) -ErrorAction SilentlyContinue |
              Where-Object { $_.Status -eq 'Up' }
  if (-not $adapters -and -not $IncludeVirtual) {
    # Fallback: include virtual if no physical adapters are up
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
  }
  if ($InterfaceName) {
    $patterns = $InterfaceName
    $adapters = $adapters | Where-Object {
      $name = $_.Name
      foreach ($p in $patterns) { if ($name -like $p) { return $true } }
      return $false
    }
  }
  $adapters
}

function Get-Stats {
  param([string[]]$Names)
  $raw = Get-NetAdapterStatistics -Name $Names -ErrorAction Stop
  foreach ($r in $raw) {
    [pscustomobject]@{
      Name            = $r.Name
      RxBytes         = [uint64]$r.ReceivedBytes
      TxBytes         = [uint64]$r.SentBytes
      Timestamp       = (Get-Date)
    }
  }
}

# --- Collect samples ---
$adapters = Get-Adapters
if (-not $adapters) { throw "No active adapters found. Try -IncludeVirtual or specify -InterfaceName." }

$names = $adapters.Name | Sort-Object -Unique
if ($names.Count -eq 0) { throw "No matching adapters." }

# Normalize sampling configuration
if ($IntervalSeconds -le 0) { $IntervalSeconds = 1 }
if ($DurationSeconds -lt $IntervalSeconds) { $DurationSeconds = $IntervalSeconds }

$sampleCount = [math]::Floor($DurationSeconds / $IntervalSeconds) + 1
if ($sampleCount -lt 2) { $sampleCount = 2 }

$allSamples = New-Object System.Collections.Generic.List[object]
$first = Get-Stats -Names $names
$allSamples.AddRange($first)

for ($i = 1; $i -lt $sampleCount; $i++) {
  Start-Sleep -Seconds $IntervalSeconds
  $s = Get-Stats -Names $names
  $allSamples.AddRange($s)
}

# --- Compute per-interval rates and overall stats ---
$timelineRows = New-Object System.Collections.Generic.List[object]
$summaryRows  = New-Object System.Collections.Generic.List[object]

foreach ($name in $names) {
  $samps = $allSamples | Where-Object Name -eq $name | Sort-Object Timestamp
  if ($samps.Count -lt 2) { continue }

  $rxMbpsList = @()
  $txMbpsList = @()

  for ($i = 1; $i -lt $samps.Count; $i++) {
    $prev = $samps[$i-1]
    $curr = $samps[$i]
    $dt   = ($curr.Timestamp - $prev.Timestamp).TotalSeconds
    if ($dt -le 0) { continue }

    # Handle 64-bit wrap-around (extremely unlikely in short sessions)
    $rxDelta = [int64]$curr.RxBytes - [int64]$prev.RxBytes
    $txDelta = [int64]$curr.TxBytes - [int64]$prev.TxBytes
    if ($rxDelta -lt 0) { $rxDelta = [int64]([uint64]$curr.RxBytes + [uint64]([uint64]::MaxValue - $prev.RxBytes)) }
    if ($txDelta -lt 0) { $txDelta = [int64]([uint64]$curr.TxBytes + [uint64]([uint64]::MaxValue - $prev.TxBytes)) }

    $rxBps  = [double]$rxDelta / $dt
    $txBps  = [double]$txDelta / $dt
    $rxMbps = ($rxBps * 8) / 1MB
    $txMbps = ($txBps * 8) / 1MB

    $rxMbpsList += $rxMbps
    $txMbpsList += $txMbps

    if ($Timeline) {
      $timelineRows.Add([pscustomobject]@{
        Name       = $name
        StartTime  = $prev.Timestamp
        EndTime    = $curr.Timestamp
        Interval_s = [math]::Round($dt,3)
        Rx_Mbps    = [math]::Round($rxMbps,3)
        Tx_Mbps    = [math]::Round($txMbps,3)
        Total_Mbps = [math]::Round($rxMbps + $txMbps,3)
      })
    }
  }

  if ($rxMbpsList.Count -gt 0) {
    $summaryRows.Add([pscustomobject]@{
      Name          = $name
      Samples       = $rxMbpsList.Count
      Duration_s    = [math]::Round((($samps[-1].Timestamp) - ($samps[0].Timestamp)).TotalSeconds,3)
      Rx_Avg_Mbps   = [math]::Round(($rxMbpsList | Measure-Object -Average).Average,3)
      Tx_Avg_Mbps   = [math]::Round(($txMbpsList | Measure-Object -Average).Average,3)
      Rx_Peak_Mbps  = [math]::Round(($rxMbpsList | Measure-Object -Maximum).Maximum,3)
      Tx_Peak_Mbps  = [math]::Round(($txMbpsList | Measure-Object -Maximum).Maximum,3)
      Total_Avg_Mbps= [math]::Round((($rxMbpsList + $txMbpsList) | Measure-Object -Average).Average,3)
      Total_Peak_Mbps= [math]::Round((($rxMbpsList + $txMbpsList) | Measure-Object -Maximum).Maximum,3)
    })
  }
}

# --- Output ---
if (-not $summaryRows -and -not $timelineRows) { Write-Warning "No data collected."; return }

switch ($As) {
  'Json' {
    $out = [pscustomobject]@{
      Summary  = $summaryRows
      Timeline = if ($Timeline) { $timelineRows } else { @() }
    }
    $out | ConvertTo-Json -Depth 5
  }
  'Csv' {
    if (-not $OutCsv) { $OutCsv = Join-Path $PWD 'GetNetBandwidth_Summary.csv' }
    $summaryRows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutCsv
    Write-Host "Summary CSV written -> $OutCsv" -ForegroundColor Green
    if ($Timeline) {
      $tl = [System.IO.Path]::ChangeExtension($OutCsv, '.timeline.csv')
      $timelineRows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $tl
      Write-Host "Timeline CSV written -> $tl" -ForegroundColor Green
    }
  }
  default {
    $summaryRows | Sort-Object -Property Total_Avg_Mbps -Descending |
      Format-Table Name,Duration_s,Samples,Rx_Avg_Mbps,Tx_Avg_Mbps,Total_Avg_Mbps,Rx_Peak_Mbps,Tx_Peak_Mbps,Total_Peak_Mbps -Auto
    if ($Timeline) {
      "`nTimeline:" | Out-Host
      $timelineRows | Format-Table Name,StartTime,EndTime,Interval_s,Rx_Mbps,Tx_Mbps,Total_Mbps -Auto
    }
  }
}
Write-Host "Done." -ForegroundColor Green