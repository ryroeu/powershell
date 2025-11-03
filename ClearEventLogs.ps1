<# 
.SYNOPSIS
  Archive (optional) and clear Windows Event Logs locally or on remote computers.

.DESCRIPTION
  - Discovers logs via Get-WinEvent -ListLog (supports remote).
  - Optionally archives each log to .evtx before clearing (timestamped, one file per log).
  - Clears logs using Clear-WinEvent (works on PowerShell 5.1 and 7+).
  - Filters: include/exclude by log name pattern, only enabled logs, minimum record count.
  - Safe: Supports -WhatIf and -Confirm; prints a summary at the end.

.EXAMPLES
  # Clear common logs locally after archiving to C:\Logs\Archive
  .\ClearEventLogs.ps1 -ArchivePath C:\Logs\Archive -Include "Application","System","Security" -Confirm

  # All enabled logs on two servers, skip archive, only logs with > 1000 records
  .\ClearEventLogs.ps1 -ComputerName srv1,srv2 -MinRecordCount 1000 -SkipArchive -Force

  # Preview what would happen
  .\ClearEventLogs.ps1 -Include 'Microsoft-Windows-*' -WhatIf
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
  [string[]] $ComputerName = @($env:COMPUTERNAME),

  # Filter which logs to touch (wildcards OK). If omitted, all logs are considered.
  [string[]] $Include,

  # Logs to exclude (wildcards OK).
  [string[]] $Exclude,

  # Only process logs that currently have at least this many records.
  [int] $MinRecordCount = 0,

  # Process only enabled logs (recommended). Use -AllLogs to override.
  [switch] $OnlyEnabled,
  [switch] $AllLogs,

  # Archive options
  [string] $ArchivePath,   # local path (for local runs) or UNC. If remote and local path, script will pull files back.
  [switch] $SkipArchive,

  # Remoting options
  [pscredential] $Credential,
  [switch] $UseSSL,

  # Behavior
  [switch] $Force,         # suppresses per-log confirmation prompts
  [switch] $VerboseSummary # show per-log counts in summary
)

begin {
  $ErrorActionPreference = 'Stop'

  function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  }

  if (-not (Test-Admin)) {
    throw "This script must be run elevated (Administrator)."
  }

  function Get-LogList {
    param(
      [string] $Computer,
      [pscredential] $Cred
    )
    # Get-WinEvent supports -ComputerName and returns LogDefinition objects
    $params = @{ ListLog='*'; ComputerName=$Computer; ErrorAction='Stop' }
    if ($Cred) { $params.Credential = $Cred }

    $logs = Get-WinEvent @params

    if (-not $AllLogs) {
      if ($OnlyEnabled) { $logs = $logs | Where-Object { $_.IsEnabled } }
    }

    if ($Include) {
      $patterns = $Include
      $logs = $logs | Where-Object {
        foreach ($p in $patterns) { if ($_.LogName -like $p) { return $true } }
        return $false
      }
    }

    if ($Exclude) {
      $ex = $Exclude
      $logs = $logs | Where-Object {
        foreach ($x in $ex) { if ($_.LogName -like $x) { return $false } }
        return $true
      }
    }

    if ($MinRecordCount -gt 0) {
      $logs = $logs | Where-Object { $_.RecordCount -ge $MinRecordCount }
    }

    $logs | Sort-Object LogName
  }

  function Invoke-Remote {
    param(
      [string] $Computer,
      [scriptblock] $ScriptBlock,
      [hashtable] $ParamHash
    )
    if ($Computer -in @($env:COMPUTERNAME, 'localhost', '.')) {
      & $ScriptBlock @ParamHash
      return
    }

    $sessParams = @{ ComputerName=$Computer; Authentication='Default' }
    if ($Credential) { $sessParams.Credential = $Credential }
    if ($UseSSL)     { $sessParams.UseSSL = $true }

    $sess = New-PSSession @sessParams
    try {
      Invoke-Command -Session $sess -ScriptBlock $ScriptBlock -ArgumentList ($ParamHash.Values)
    }
    finally {
      Remove-PSSession $sess
    }
  }

  # Remote export + clear block (runs on target when remote)
  $sbExportAndClear = {
    param($LogName, $DoArchive, $DestPath, $TimeStamp, $ForceFlag)
    $ErrorActionPreference = 'Stop'

    if ($DoArchive -and $DestPath) {
      # Ensure target folder exists
      New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
      $safe = ($LogName -replace '[\\/:\*\?\"<>\|]', '_')
      $file = Join-Path $DestPath ("{0}_{1}.evtx" -f $safe, $TimeStamp)
      # Export using wevtutil (fast and reliable). Export-PSSession alternatives don't apply.
      wevtutil epl "$LogName" "$file"
    }

    # Clear log
    if ($ForceFlag) {
      Clear-WinEvent -LogName $LogName -ErrorAction Stop
    } else {
      Clear-WinEvent -LogName $LogName -Confirm
    }

    # Return a tiny object for summary
    try {
      $after = (Get-WinEvent -ListLog $LogName).RecordCount
    } catch {
      $after = $null
    }

    [pscustomobject]@{ LogName=$LogName; Cleared=$true; Remaining=$after }
  }

  $summary = New-Object System.Collections.Generic.List[object]
  $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
}

process {
  foreach ($computer in $ComputerName) {
    Write-Verbose "Processing $computer ..."

    # Build list
    $logs = Get-LogList -Computer $computer -Cred $Credential
    if (-not $logs) {
      Write-Host "[$computer] No logs matched the criteria." -ForegroundColor Yellow
      continue
    }

    # Decide archive path per computer
    $remoteArchiveUNC = $null
    $pullBack = $false

    if (-not $SkipArchive -and $ArchivePath) {
      if ($computer -in @($env:COMPUTERNAME, 'localhost', '.')) {
        $remoteArchiveUNC = Join-Path $ArchivePath $computer
      } else {
        # If ArchivePath is UNC, write there directly from remote.
        if ($ArchivePath -match '^[\\\\]{2,}') {
          $remoteArchiveUNC = Join-Path $ArchivePath $computer
        } else {
          # Use temp on remote; we will pull back after clearing.
          $remoteArchiveUNC = "C:\Windows\Temp\EventArchive\$computer"
          $pullBack = $true
        }
      }
    }

    foreach ($log in $logs) {
      $target = "$computer :: $($log.LogName)"
      $doArchive = (-not $SkipArchive) -and [string]::IsNullOrEmpty($ArchivePath) -eq $false

      if ($PSCmdlet.ShouldProcess($target, "$(if($doArchive){'Archive & '})Clear")) {
        $logArgs = @{
          LogName   = $log.LogName
          DoArchive = $doArchive
          DestPath  = $remoteArchiveUNC
          TimeStamp = $ts
          ForceFlag = $Force.IsPresent
        }

        try {
          $result = Invoke-Remote -Computer $computer -ScriptBlock $sbExportAndClear -ParamHash $logArgs
          if ($result) { $summary.Add([pscustomobject]@{ Computer=$computer; LogName=$result.LogName; Cleared=$true; Remaining=$result.Remaining }) }
          if ($doArchive -and $pullBack) {
            # Pull archives back to local ArchivePath\<computer>
            $sessParams = @{ ComputerName=$computer }
            if ($Credential) { $sessParams.Credential = $Credential }
            if ($UseSSL)     { $sessParams.UseSSL = $true }
            $sess = New-PSSession @sessParams
            try {
              $remoteDir = $remoteArchiveUNC
              $localDir  = Join-Path $ArchivePath $computer
              New-Item -ItemType Directory -Path $localDir -Force | Out-Null
              Copy-Item -FromSession $sess -Path (Join-Path $remoteDir '*') -Destination $localDir -Force -ErrorAction SilentlyContinue
            }
            finally { Remove-PSSession $sess }
          }
        }
        catch {
          Write-Warning "[$computer] $($log.LogName): $($_.Exception.Message)"
          $summary.Add([pscustomobject]@{ Computer=$computer; LogName=$log.LogName; Cleared=$false; Remaining=$log.RecordCount })
        }
      }
    }
  }
}

end {
  # Summary
  if ($VerboseSummary) {
    $summary | Sort-Object Computer,LogName | Format-Table Computer,LogName,Cleared,Remaining -Auto
  } else {
    $ok = ($summary | Where-Object Cleared).Count
    $bad = ($summary | Where-Object { -not $_.Cleared }).Count
    Write-Host ("Completed. Logs cleared: {0}, Failed: {1}" -f $ok, $bad) -ForegroundColor Green
  }
}
