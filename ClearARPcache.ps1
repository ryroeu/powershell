<# 
.SYNOPSIS
  Clear the ARP/Neighbor cache locally or on remote Windows computers using modern cmdlets.

.DESCRIPTION
  Uses Get-NetNeighbor / Remove-NetNeighbor (NetTCPIP) with optional CIM remoting.
  Skips static (Permanent) entries by default. Supports IPv4 and IPv6.

.EXAMPLES
  # Clear all dynamic IPv4 entries on the local machine
  .\ClearARPcache.ps1

  # Clear on specific interfaces only
  .\ClearARPcache.ps1 -InterfaceAlias 'Ethernet*','Wi-Fi'

  # Target specific IP(s)
  .\ClearARPcache.ps1 -IPAddress 192.168.1.1,192.168.1.50

  # Include IPv6 too, across two servers (device code auth not needed; uses CIM)
  .\ClearARPcache.ps1 -ComputerName srv1,srv2 -AddressFamily Both -Force

  # Also remove static (Permanent) entries (careful!)
  .\ClearARPcache.ps1 -IncludePermanent -Confirm
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
  [string[]] $ComputerName = @($env:COMPUTERNAME),

  # Filter by interface name (wildcards ok). If omitted, all interfaces are considered.
  [string[]] $InterfaceAlias,

  # Target specific address(es) (IPv4 or IPv6). If omitted, all matching entries are cleared.
  [string[]] $IPAddress,

  [ValidateSet('IPv4','IPv6','Both')] [string] $AddressFamily = 'IPv4',

  # By default we skip Permanent entries. Use this switch to include them.
  [switch] $IncludePermanent,

  # Remoting
  [pscredential] $Credential,

  # Behavior
  [switch] $Force   # suppress per-entry confirmation prompts
)

begin {
  $ErrorActionPreference = 'Stop'

  function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = [Security.Principal.WindowsPrincipal]::new($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  }
  if (-not (Test-Admin)) { throw "Run elevated (Administrator) to clear ARP/Neighbor cache." }

  # Map AddressFamily to values the cmdlets expect
  function Get-Families {
    switch ($AddressFamily) {
      'IPv4' { @('IPv4') }
      'IPv6' { @('IPv6') }
      'Both' { @('IPv4','IPv6') }
    }
  }

  # Build CIM sessions where needed
  function New-MyCimSession {
    param([string]$Computer)
    if ($Computer -in @($env:COMPUTERNAME,'localhost','.')) { return $null }
    $opts = New-CimSessionOption -Protocol Wsman
    if ($Credential) { return New-CimSession -ComputerName $Computer -Credential $Credential -SessionOption $opts }
    else             { return New-CimSession -ComputerName $Computer -SessionOption $opts }
  }

  # Core: get candidates and clear them using Remove-NetNeighbor
  $sbClear = {
    param(
      [string[]] $Families,
      [string[]] $IfAlias,
      [string[]] $IPList,
      [bool]     $IncPermanent,
      [bool]     $IsForce,
      [bool]     $HasWhatIf
    )
    $ErrorActionPreference = 'Stop'

    # Prefer NetTCPIP cmdlets; fallback to netsh if not available
    $haveNetTCPIP = Get-Command Get-NetNeighbor -ErrorAction SilentlyContinue
    if (-not $haveNetTCPIP) {
      if ($HasWhatIf) { return [pscustomobject]@{ UsedFallback=$true; Cleared=-1; Failed=0 } }
      # netsh fallback clears whole neighbor cache per family
      $count = 0; $fail = 0
      foreach ($fam in $Families) {
        try {
          if ($fam -eq 'IPv4') { & netsh interface ip delete arpcache | Out-Null }
          else                 { & netsh interface ipv6 delete neighbors | Out-Null }
          $count++
        } catch { $fail++ }
      }
      return [pscustomobject]@{ UsedFallback=$true; Cleared=$count; Failed=$fail }
    }

    # Build candidate list
    $candidates = @()
    foreach ($fam in $Families) {
      $params = @{ AddressFamily=$fam }
      if ($IfAlias) { $params.InterfaceAlias = $IfAlias }
      $entries = Get-NetNeighbor @params -ErrorAction SilentlyContinue
      if ($IPList) { $entries = $entries | Where-Object { $_.IPAddress -in $IPList } }
      if (-not $IncPermanent) { $entries = $entries | Where-Object { $_.State -ne 'Permanent' } }
      # Also skip Unreachable/Incomplete noise (optional)
      $entries = $entries | Where-Object { $_.State -in @('Reachable','Stale','Delay','Probe','Unknown') }
      $candidates += $entries
    }

    $cleared = 0; $failed = 0
    foreach ($n in ($candidates | Sort-Object InterfaceIndex,IPAddress -Unique)) {
      $target = "{0} [{1}] {2}" -f $n.InterfaceAlias,$n.AddressFamily,$n.IPAddress
      $cap = "Remove neighbor"
      if ($HasWhatIf -or $PSCmdlet.ShouldProcess($target,$cap)) {
        try {
          if ($IsForce) {
            Remove-NetNeighbor -InterfaceIndex $n.InterfaceIndex -IPAddress $n.IPAddress -Confirm:$false -ErrorAction Stop
          } else {
            Remove-NetNeighbor -InterfaceIndex $n.InterfaceIndex -IPAddress $n.IPAddress -ErrorAction Stop
          }
          $cleared++
        } catch { $failed++ }
      }
    }
    [pscustomobject]@{ UsedFallback=$false; Cleared=$cleared; Failed=$failed }
  }

  $families = Get-Families
  $overall  = New-Object System.Collections.Generic.List[object]
}

process {
  foreach ($comp in $ComputerName) {
    $sess = $null
    try {
      $sess = New-MyCimSession -Computer $comp
      $callArgs = @{
        Families     = $families
        IfAlias      = $InterfaceAlias
        IPList       = $IPAddress
        IncPermanent = $IncludePermanent.IsPresent
        IsForce      = $Force.IsPresent
        HasWhatIf    = $WhatIfPreference -eq $true
      }

      if ($sess) {
        $res = Invoke-Command -Session $sess -ScriptBlock $sbClear -ArgumentList ($callArgs.Families,$callArgs.IfAlias,$callArgs.IPList,$callArgs.IncPermanent,$callArgs.IsForce,$callArgs.HasWhatIf)
      } else {
        $res = & $sbClear @callArgs
      }

      $overall.Add([pscustomobject]@{
        Computer   = $comp
        UsedFallback = $res.UsedFallback
        Cleared    = $res.Cleared
        Failed     = $res.Failed
      })
    }
    finally { if ($sess) { $sess | Remove-CimSession } }
  }
}

end {
  $overall | Format-Table Computer,UsedFallback,Cleared,Failed -Auto
  $totCleared = ($overall | Measure-Object Cleared -Sum).Sum
  $totFailed  = ($overall | Measure-Object Failed  -Sum).Sum
  Write-Host ("Total cleared: {0}, failed: {1}" -f $totCleared, $totFailed) -ForegroundColor Green
}
