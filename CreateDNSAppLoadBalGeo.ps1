<# 
.SYNOPSIS
  Bulk create/maintain DNS round-robin records on a Windows DNS Server from a CSV or JSON plan.

.DESCRIPTION
  For each record spec in the input plan, the script:
   - Validates zone existence on the target DNS server
   - (Optionally) health-probes backends (TCP/HTTP) before adding
   - Adds missing A/AAAA records, and (optionally) removes extras in -ReplaceExisting mode
   - Sets TTL per-record
  Uses DnsServer module (no dnscmd). Works on Windows PowerShell 5.1 and PowerShell 7+.

.INPUT FORMAT
  CSV columns (case-insensitive):
    ZoneName, RecordName, IPv4 (semicolon-separated), IPv6 (semicolon-separated),
    TTL, ReplaceExisting (true/false), HealthProbe (true/false),
    ProbeType (TCP|HTTP), ProbePort, ProbePath

  JSON structure:
    [
      {
        "ZoneName": "contoso.com",
        "RecordName": "app",
        "IPv4": ["10.0.1.10","10.0.1.11"],
        "IPv6": ["2001:db8::10"],
        "TTL": 60,
        "ReplaceExisting": true,
        "HealthProbe": true,
        "ProbeType": "HTTP",
        "ProbePort": 443,
        "ProbePath": "/healthz"
      }
    ]

.EXAMPLE
  # From CSV on local DNS server
  .\CreateDNSAppLoadBalGen.ps1 -Csv .\records.csv

  # From JSON, target remote DNS and preview with -WhatIf
  .\CreateDNSAppLoadBalGen.ps1 -Json .\records.json -DnsServer DNSSRV01 -WhatIf

  # From CSV, force replace and enable health checks (overrides per-record flags)
  .\CreateDNSAppLoadBalGen.ps1 -Csv .\records.csv -ReplaceExisting -HealthProbe -ProbeType TCP -ProbePort 443
  
.EXAMPLE
ZoneName,RecordName,IPv4,IPv6,TTL,ReplaceExisting,HealthProbe,ProbeType,ProbePort,ProbePath
contoso.com,app,10.0.1.10;10.0.1.11,,60,TRUE,FALSE,,,
contoso.com,api,10.0.2.10;10.0.2.11,2001:db8::10,45,TRUE,TRUE,HTTP,443,/healthz
contoso.com,web,10.0.3.10;10.0.3.11,,30,FALSE,TRUE,TCP,443,

.NOTES
  - Round-robin is achieved by maintaining multiple A/AAAA records with the same name.
  - Small TTLs (30–60s) improve re-query behavior for better distribution.
  - Health probes here are *pre-creation checks*; ongoing health-based rotation needs a real LB or DNS policies.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
  [Parameter(ParameterSetName='CSV',  Mandatory)] [string] $Csv,
  [Parameter(ParameterSetName='JSON', Mandatory)] [string] $Json,

  [string] $DnsServer = $env:COMPUTERNAME,

  # Global overrides (optional). If supplied, these supersede values in the plan.
  [Nullable[int]] $TTL,
  [switch] $ReplaceExisting,
  [switch] $HealthProbe,
  [ValidateSet('TCP','HTTP')] [string] $ProbeType,
  [Nullable[int]] $ProbePort,
  [string] $ProbePath = '/',

  # Stop processing after the first error
  [switch] $StopOnError
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

  function Convert-Plan {
    param([hashtable]$Overrides)
    switch ($PSCmdlet.ParameterSetName) {
      'CSV'  {
        if (-not (Test-Path $Csv)) { throw "CSV not found: $Csv" }
        $rows = Import-Csv -Path $Csv
        foreach ($r in $rows) {
          [pscustomobject]@{
            ZoneName        = $r.ZoneName
            RecordName      = $r.RecordName
            IPv4            = if ($r.IPv4) { $r.IPv4 -split ';' } else { @() }
            IPv6            = if ($r.IPv6) { $r.IPv6 -split ';' } else { @() }
            TTL             = if ($Overrides.TTL) { $Overrides.TTL } elseif ($r.TTL) { [int]$r.TTL } else { 60 }
            ReplaceExisting = if ($Overrides.ReplaceExisting) { $true } else { [bool]::Parse(($r.ReplaceExisting ?? 'false')) }
            HealthProbe     = if ($Overrides.HealthProbe)     { $true } else { [bool]::Parse(($r.HealthProbe ?? 'false')) }
            ProbeType       = if ($Overrides.ProbeType)       { $Overrides.ProbeType } else { ($r.ProbeType ?? 'TCP') }
            ProbePort       = if ($Overrides.ProbePort)       { [int]$Overrides.ProbePort } elseif ($r.ProbePort) { [int]$r.ProbePort } else { $null }
            ProbePath       = if ($Overrides.ProbePath)       { $Overrides.ProbePath } else { ($r.ProbePath ?? '/') }
          }
        }
      }
      'JSON' {
        if (-not (Test-Path $Json)) { throw "JSON not found: $Json" }
        $rows = Get-Content $Json -Raw | ConvertFrom-Json
        foreach ($r in $rows) {
          [pscustomobject]@{
            ZoneName        = $r.ZoneName
            RecordName      = $r.RecordName
            IPv4            = @($r.IPv4) | Where-Object { $_ }
            IPv6            = @($r.IPv6) | Where-Object { $_ }
            TTL             = if ($Overrides.TTL) { $Overrides.TTL } elseif ($r.TTL) { [int]$r.TTL } else { 60 }
            ReplaceExisting = if ($Overrides.ReplaceExisting) { $true } else { [bool]$r.ReplaceExisting }
            HealthProbe     = if ($Overrides.HealthProbe)     { $true } else { [bool]$r.HealthProbe }
            ProbeType       = if ($Overrides.ProbeType)       { $Overrides.ProbeType } else { ($r.ProbeType ?? 'TCP') }
            ProbePort       = if ($Overrides.ProbePort)       { [int]$Overrides.ProbePort } elseif ($r.ProbePort) { [int]$r.ProbePort } else { $null }
            ProbePath       = if ($Overrides.ProbePath)       { $Overrides.ProbePath } else { ($r.ProbePath ?? '/') }
          }
        }
      }
    }
  }

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
      $path = if ($Path.StartsWith('/')) { $Path } else { "/$Path" }
      $uri = [uri]::new(("http://{0}:{1}{2}" -f $Address,$Port,$path))
      $h = [System.Net.Http.HttpClient]::new()
      $h.Timeout = [TimeSpan]::FromMilliseconds($TimeoutMs)
      $resp = $h.GetAsync($uri).GetAwaiter().GetResult()
      $ok = ($resp.IsSuccessStatusCode -or ([int]$resp.StatusCode -ge 200 -and [int]$resp.StatusCode -lt 400))
      $h.Dispose()
      return $ok
    } catch { return $false }
  }

  function Test-Healthy {
    param(
      [string[]]$Addresses,
      [bool]$Enabled,
      [string]$ProbeType,
      [Nullable[int]]$ProbePort,
      [string]$ProbePath
    )
    if (-not $Enabled -or -not $Addresses -or $Addresses.Count -eq 0) { return ,$Addresses }
    $port = if ($ProbeType -eq 'HTTP') { if ($ProbePort) { $ProbePort } else { 80 } }
            else                        { if ($ProbePort) { $ProbePort } else { throw "-ProbePort required for TCP health probe." } }
    $okList = New-Object System.Collections.Generic.List[string]
    foreach ($ip in $Addresses) {
      $ok = if ($ProbeType -eq 'TCP') { Test-Tcp -Address $ip -Port $port }
            else { Test-Http -Address $ip -Port $port -Path $ProbePath }
      if ($ok) { $okList.Add($ip) } else { Write-Warning "Probe failed: $ip (${ProbeType}:${port} ${ProbePath})" }
    }
    ,$okList.ToArray()
  }

  function Get-Current {
    param([string]$Zone,[string]$Name,[string]$Type)
    try { Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $Zone -Name $Name -RRType $Type -ErrorAction Stop }
    catch { @() }
  }

  # Compose overrides
  $ovr = @{
    TTL             = $TTL
    ReplaceExisting = $ReplaceExisting.IsPresent
    HealthProbe     = $HealthProbe.IsPresent
    ProbeType       = $ProbeType
    ProbePort       = $ProbePort
    ProbePath       = $ProbePath
  }

  # Load and normalize the plan
  $plan = Convert-Plan -Overrides $ovr
  if (-not $plan -or $plan.Count -eq 0) { throw "No records found in input." }

  # Validate zones exist up front
  $zones = $plan | Select-Object -ExpandProperty ZoneName -Unique
  foreach ($z in $zones) {
    try { Get-DnsServerZone -ComputerName $DnsServer -Name $z -ErrorAction Stop | Out-Null }
    catch { throw "Zone '$z' not found on DNS server '$DnsServer'." }
  }

  $results = New-Object System.Collections.Generic.List[object]
}

process {
  foreach ($rec in $plan) {
    try {
      $zone   = $rec.ZoneName.Trim('.')
      $name   = $rec.RecordName.Trim('.')
      $fqdn   = "$name.$zone"
      $ttlSec = if ($rec.TTL) { [int]$rec.TTL } else { 60 }

      # Filter healthy addresses if requested
      $ipv4 = @(Test-Healthy -Addresses $rec.IPv4 -Enabled $rec.HealthProbe -ProbeType $rec.ProbeType -ProbePort $rec.ProbePort -ProbePath $rec.ProbePath)
      $ipv6 = @(Test-Healthy -Addresses $rec.IPv6 -Enabled $rec.HealthProbe -ProbeType $rec.ProbeType -ProbePort $rec.ProbePort -ProbePath $rec.ProbePath)

      # Current records
      $currA    = @(Get-Current -Zone $zone -Name $name -Type 'A')
      $currAAAA = @(Get-Current -Zone $zone -Name $name -Type 'AAAA')

      $curr4 = @($currA    | ForEach-Object { $_.RecordData.IPv4Address.IPAddressToString })
      $curr6 = @($currAAAA | ForEach-Object { $_.RecordData.IPv6Address.IPAddressToString })

      $add4  = @($ipv4 | Where-Object { $_ -and ($_ -notin $curr4) })
      $keep4 = @($ipv4 | Where-Object { $_ -in $curr4 })
      $drop4 = if ($rec.ReplaceExisting) { @($curr4 | Where-Object { $_ -notin $ipv4 }) } else { @() }

      $add6  = @($ipv6 | Where-Object { $_ -and ($_ -notin $curr6) })
      $keep6 = @($ipv6 | Where-Object { $_ -in $curr6 })
      $drop6 = if ($rec.ReplaceExisting) { @($curr6 | Where-Object { $_ -notin $ipv6 }) } else { @() }

      Write-Host "[$DnsServer] $fqdn (TTL=$ttlSec) — add A:[$($add4 -join ', ')] AAAA:[$($add6 -join ', ')]" -ForegroundColor Cyan
      if ($PSCmdlet.ShouldProcess($fqdn, 'Apply DNS RR set')) {

        foreach ($ip in $add4) {
          Add-DnsServerResourceRecordA -ComputerName $DnsServer -ZoneName $zone -Name $name `
            -IPv4Address $ip -TimeToLive ([TimeSpan]::FromSeconds($ttlSec)) -AllowUpdateAny -CreatePtr:$false | Out-Null
        }
        foreach ($ip in $add6) {
          Add-DnsServerResourceRecordAAAA -ComputerName $DnsServer -ZoneName $zone -Name $name `
            -IPv6Address $ip -TimeToLive ([TimeSpan]::FromSeconds($ttlSec)) -AllowUpdateAny | Out-Null
        }
        foreach ($ip in $drop4) {
          Remove-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $zone -Name $name -RRType A -RecordData $ip -Force | Out-Null
        }
        foreach ($ip in $drop6) {
          Remove-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $zone -Name $name -RRType AAAA -RecordData $ip -Force | Out-Null
        }
      }

      # Final state
      $finalA    = @((Get-Current -Zone $zone -Name $name -Type 'A')    | ForEach-Object { $_.RecordData.IPv4Address.IPAddressToString })
      $finalAAAA = @((Get-Current -Zone $zone -Name $name -Type 'AAAA') | ForEach-Object { $_.RecordData.IPv6Address.IPAddressToString })

      $results.Add([pscustomobject]@{
        ZoneName        = $zone
        RecordName      = $name
        FQDN            = $fqdn
        TTL             = $ttlSec
        AddedIPv4       = ($add4 -join ', ')
        KeptIPv4        = ($keep4 -join ', ')
        RemovedIPv4     = ($drop4 -join ', ')
        FinalIPv4       = ($finalA -join  ', ')
        AddedIPv6       = ($add6 -join ', ')
        KeptIPv6        = ($keep6 -join ', ')
        RemovedIPv6     = ($drop6 -join ', ')
        FinalIPv6       = ($finalAAAA -join ', ')
        HealthProbe     = [bool]$rec.HealthProbe
        ProbeType       = $rec.ProbeType
        ProbePort       = $rec.ProbePort
        ProbePath       = $rec.ProbePath
        ReplaceExisting = [bool]$rec.ReplaceExisting
      })
    }
    catch {
      Write-Warning "Failed: $($_.Exception.Message)"
      if ($StopOnError) { throw }
    }
  }
}

end {
  if ($results.Count) {
    "`nSummary:" | Out-Host
    $results | Sort-Object ZoneName,RecordName | Format-Table ZoneName,RecordName,TTL,FinalIPv4,FinalIPv6,ReplaceExisting -Auto
  }
}
