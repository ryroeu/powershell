<# 
.SYNOPSIS
  Create/maintain DNS round-robin records for an app (Windows DNS Server).

.DESCRIPTION
  - Adds A/AAAA records for the same <host> to enable round-robin load balancing.
  - Optional health checks (TCP or HTTP) can validate backends before adding them.
  - Idempotent: can add only-missing records or fully replace the current set.

.PARAMETER ZoneName
  DNS zone (e.g., contoso.com).

.PARAMETER RecordName
  Host portion only (e.g., app). FQDN becomes <RecordName>.<ZoneName>.

.PARAMETER IPv4
  One or more IPv4 addresses for backends.

.PARAMETER IPv6
  One or more IPv6 addresses for backends.

.PARAMETER DnsServer
  Target DNS server (name or IP). Defaults to local machine.

.PARAMETER TTL
  Time-to-live for created records (default 60s).

.PARAMETER ReplaceExisting
  If set, removes any existing A/AAAA for this name that are NOT in the supplied lists.

.PARAMETER HealthProbe
  Enable health checks before adding addresses.

.PARAMETER ProbeType
  'TCP' (default) or 'HTTP'.

.PARAMETER ProbePort
  Port for probe. Default 80 for HTTP, 443 often used; for TCP you must specify.

.PARAMETER ProbePath
  For HTTP probes (default '/'). A 200-399 status is considered healthy.

.PARAMETER TimeoutMs
  Probe timeout in milliseconds (default 1500ms).

.EXAMPLES
  # Basic RR with 3 IPv4 backends (adds missing, keeps existing)
  .\CreateDNSAppLoadBal.ps1 -ZoneName contoso.com -RecordName app `
    -IPv4 10.0.1.10,10.0.1.11,10.0.1.12 -TTL 60

  # Replace current set with exactly these IPv4+IPv6 addresses
  .\CreateDNSAppLoadBal.ps1 -ZoneName contoso.com -RecordName api `
    -IPv4 10.0.2.10,10.0.2.11 -IPv6 2001:db8::10 -ReplaceExisting

  # Only add healthy backends (HTTP /healthz on 443)
  .\CreateDNSAppLoadBal.ps1 -ZoneName contoso.com -RecordName web `
    -IPv4 10.0.10.10,10.0.10.11 -HealthProbe -ProbeType HTTP -ProbePort 443 -ProbePath /healthz

  # Operate on a remote DNS server with what-if preview
  .\CreateDNSAppLoadBal.ps1 -ZoneName contoso.com -RecordName app `
    -IPv4 10.1.1.10,10.1.1.11 -DnsServer DNSSRV01 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
  [Parameter(Mandatory)] [string]   $ZoneName,
  [Parameter(Mandatory)] [string]   $RecordName,
  [string[]]                        $IPv4,
  [string[]]                        $IPv6,
  [string]                          $DnsServer = $env:COMPUTERNAME,
  [ValidateRange(1,86400)] [int]    $TTL = 60,
  [switch]                          $ReplaceExisting,

  [switch]                          $HealthProbe,
  [ValidateSet('TCP','HTTP')] [string] $ProbeType = 'TCP',
  [int]                             $ProbePort,
  [string]                          $ProbePath = '/',
  [int]                             $TimeoutMs = 1500
)

begin {
  $ErrorActionPreference = 'Stop'
  function Install-ModuleIfMissing {
    param([string]$Name,[string]$MinVersion='0.0.0')
    if (-not (Get-Module -ListAvailable -Name $Name)) {
      Install-Module $Name -Scope CurrentUser -Force -AllowClobber -MinimumVersion $MinVersion
    }
    Import-Module $Name -MinimumVersion $MinVersion -ErrorAction Stop
  }

  Install-ModuleIfMissing DnsServer -MinVersion '1.0.0.0'

  if (-not $IPv4 -and -not $IPv6) {
    throw "Provide at least one address via -IPv4 and/or -IPv6."
  }

  if ($HealthProbe) {
    if ($ProbeType -eq 'TCP' -and -not $ProbePort) {
      throw "-ProbePort is required for TCP probes."
    }
    if ($ProbeType -eq 'HTTP' -and -not $ProbePort) {
      $ProbePort = 80
    }
  }

  $fqdn = "{0}.{1}" -f $RecordName.Trim('.'), $ZoneName.Trim('.')

  # Validate zone exists on the target server
  try {
    $null = Get-DnsServerZone -ComputerName $DnsServer -Name $ZoneName -ErrorAction Stop
  } catch {
    throw "Zone '$ZoneName' not found on DNS server '$DnsServer'."
  }

  # Helper: probe functions (PS5.1 + PS7 compatible)
  function Test-Tcp {
    param([string]$Address,[int]$Port,[int]$TimeoutMs=1500)
    try {
      $client = [System.Net.Sockets.TcpClient]::new()
      $iar = $client.BeginConnect($Address, $Port, $null, $null)
      if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs)) { $client.Close(); return $false }
      $client.EndConnect($iar); $client.Close(); return $true
    } catch { return $false }
  }

  function Test-Http {
    param([string]$Address,[int]$Port,[string]$Path='/',[int]$TimeoutMs=1500)
    try {
      $uri = [uri]::new(("http://{0}:{1}{2}" -f $Address,$Port, (if ($Path.StartsWith('/')){$Path}else{"/$Path"})))
      $h = [System.Net.Http.HttpClient]::new()
      $h.Timeout = [TimeSpan]::FromMilliseconds($TimeoutMs)
      $resp = $h.GetAsync($uri).GetAwaiter().GetResult()
      $ok = ($resp.IsSuccessStatusCode -or ([int]$resp.StatusCode -ge 200 -and [int]$resp.StatusCode -lt 400))
      $h.Dispose()
      return $ok
    } catch { return $false }
  }

  function Test-Healthy {
    param([string[]]$Addresses,[ValidateSet('IPv4','IPv6')]$Family)
    if (-not $HealthProbe -or -not $Addresses) { return ,$Addresses }
    $port = $ProbePort
    $healthy = New-Object System.Collections.Generic.List[string]
    foreach ($ip in $Addresses) {
      $ok = if ($ProbeType -eq 'TCP') { Test-Tcp -Address $ip -Port $port -TimeoutMs $TimeoutMs }
            else { Test-Http -Address $ip -Port $port -Path $ProbePath -TimeoutMs $TimeoutMs }
      if ($ok) { $healthy.Add($ip) } else { Write-Warning "$Family backend failed probe: $ip" }
    }
    ,$healthy.ToArray()
  }

  # Fetch current records
  function Get-CurrentA {
    try { (Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Name $RecordName -RRType A -ErrorAction Stop) } catch { @() }
  }
  function Get-CurrentAAAA {
    try { (Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -Name $RecordName -RRType AAAA -ErrorAction Stop) } catch { @() }
  }

  $desiredIPv4 = @(Test-Healthy -Addresses $IPv4 -Family 'IPv4')
  $desiredIPv6 = @(Test-Healthy -Addresses $IPv6 -Family 'IPv6')
}

process {
  # Compute deltas (IPv4)
  $currA = @(Get-CurrentA)
  $currIPv4 = @($currA | ForEach-Object { $_.RecordData.IPv4Address.IPAddressToString })
  $toAdd4 = @($desiredIPv4 | Where-Object { $_ -notin $currIPv4 })
  $toKeep4 = @($desiredIPv4 | Where-Object { $_ -in $currIPv4 })
  $toDrop4 = if ($ReplaceExisting) { @($currIPv4 | Where-Object { $_ -notin $desiredIPv4 }) } else { @() }

  # Compute deltas (IPv6)
  $currAAAA = @(Get-CurrentAAAA)
  $currIPv6 = @($currAAAA | ForEach-Object { $_.RecordData.IPv6Address.IPAddressToString })
  $toAdd6 = @($desiredIPv6 | Where-Object { $_ -notin $currIPv6 })
  $toKeep6 = @($desiredIPv6 | Where-Object { $_ -in $currIPv6 })
  $toDrop6 = if ($ReplaceExisting) { @($currIPv6 | Where-Object { $_ -notin $desiredIPv6 }) } else { @() }

  Write-Host "Target: $fqdn  (TTL=$TTL s) on DNS server $DnsServer" -ForegroundColor Cyan
  if ($HealthProbe) {
    Write-Host "Health probe: $ProbeType on port $ProbePort, timeout ${TimeoutMs}ms, path '$ProbePath'" -ForegroundColor Cyan
  }

  # Add new A
  foreach ($ip in $toAdd4) {
    if ($PSCmdlet.ShouldProcess("$fqdn (A) -> $ip", 'Add record')) {
      Add-DnsServerResourceRecordA -ComputerName $DnsServer -ZoneName $ZoneName -Name $RecordName `
        -IPv4Address $ip -TimeToLive ([TimeSpan]::FromSeconds($TTL)) -AllowUpdateAny -CreatePtr:$false | Out-Null
      Write-Host "Added A $fqdn -> $ip" -ForegroundColor Green
    }
  }

  # Add new AAAA
  foreach ($ip in $toAdd6) {
    if ($PSCmdlet.ShouldProcess("$fqdn (AAAA) -> $ip", 'Add record')) {
      Add-DnsServerResourceRecordAAAA -ComputerName $DnsServer -ZoneName $ZoneName -Name $RecordName `
        -IPv6Address $ip -TimeToLive ([TimeSpan]::FromSeconds($TTL)) -AllowUpdateAny | Out-Null
      Write-Host "Added AAAA $fqdn -> $ip" -ForegroundColor Green
    }
  }

  # Remove extras when replacing
  foreach ($ip in $toDrop4) {
    if ($PSCmdlet.ShouldProcess("$fqdn (A) -> $ip", 'Remove record')) {
      $rec = $currA | Where-Object { $_.RecordData.IPv4Address.IPAddressToString -eq $ip }
      if ($rec) {
        Remove-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -RRType A -Name $RecordName -RecordData $ip -Force | Out-Null
        Write-Host "Removed A $fqdn -> $ip" -ForegroundColor Yellow
      }
    }
  }
  foreach ($ip in $toDrop6) {
    if ($PSCmdlet.ShouldProcess("$fqdn (AAAA) -> $ip", 'Remove record')) {
      Remove-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $ZoneName -RRType AAAA -Name $RecordName -RecordData $ip -Force | Out-Null
      Write-Host "Removed AAAA $fqdn -> $ip" -ForegroundColor Yellow
    }
  }

  # Summarize
  $finalA    = @((Get-CurrentA)    | ForEach-Object { $_.RecordData.IPv4Address.IPAddressToString })
  $finalAAAA = @((Get-CurrentAAAA) | ForEach-Object { $_.RecordData.IPv6Address.IPAddressToString })

  Write-Host "`nSummary for $fqdn" -ForegroundColor Cyan
  "{0,-10} {1}" -f "Keep(A):",  ($toKeep4 -join ', ') | Write-Host
  "{0,-10} {1}" -f "Added(A):", ($toAdd4 -join ', ')  | Write-Host
  if ($ReplaceExisting) { "{0,-10} {1}" -f "Removed(A):",($toDrop4 -join ', ') | Write-Host }
  if ($IPv6) {
    "{0,-10} {1}" -f "Keep(AAAA):",  ($toKeep6 -join ', ') | Write-Host
    "{0,-10} {1}" -f "Added(AAAA):", ($toAdd6 -join ', ')  | Write-Host
    if ($ReplaceExisting) { "{0,-10} {1}" -f "Removed(AAAA):",($toDrop6 -join ', ') | Write-Host }
  }
  "{0,-10} {1}" -f "Final(A):",    ($finalA -join ', ')    | Write-Host
  "{0,-10} {1}" -f "Final(AAAA):", ($finalAAAA -join ', ') | Write-Host
}
