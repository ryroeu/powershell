<#
.SYNOPSIS
    Archives and clears selected Windows event logs locally or remotely.
.DESCRIPTION
    Enabled logs are selected by default. Use -AllLogs to include disabled logs. When -ArchivePath is
    supplied, remote logs are exported to a temporary file and copied back through the PowerShell session.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name')]
    [string[]]$ComputerName = @($env:COMPUTERNAME),

    [string[]]$Include = @('Application', 'System', 'Security'),

    [string[]]$Exclude,

    [ValidateRange(0, [long]::MaxValue)]
    [long]$MinRecordCount = 0,

    [switch]$AllLogs,

    [string]$ArchivePath,

    [switch]$SkipArchive,

    [pscredential]$Credential,

    [switch]$UseSSL
)

begin {
    $summary = [Collections.Generic.List[object]]::new()
    $getLogBlock = {
        param($IncludePattern, $ExcludePattern, $MinimumRecords, $IncludeDisabled)

        Get-WinEvent -ListLog '*' -ErrorAction SilentlyContinue |
            Where-Object {
                $log = $_
                $included = $IncludePattern.Count -eq 0 -or @($IncludePattern | Where-Object { $log.LogName -like $_ }).Count -gt 0
                $excluded = @($ExcludePattern | Where-Object { $log.LogName -like $_ }).Count -gt 0
                $included -and -not $excluded -and ($IncludeDisabled -or $log.IsEnabled) -and $log.RecordCount -ge $MinimumRecords
            } |
            Select-Object LogName, RecordCount, IsEnabled
    }
    $clearBlock = {
        param($EventLogName, $BackupPath)

        if ($BackupPath) {
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $BackupPath) -Force
            & wevtutil.exe epl $EventLogName $BackupPath /ow:true
            if ($LASTEXITCODE -ne 0) {
                throw "wevtutil.exe failed to export '$EventLogName' with exit code $LASTEXITCODE."
            }
        }
        Clear-WinEvent -LogName $EventLogName -Confirm:$false -ErrorAction Stop
    }
}

process {
    foreach ($computer in $ComputerName) {
        $isLocal = $computer -in '.', 'localhost', $env:COMPUTERNAME
        $session = $null
        try {
            if ($isLocal) {
                $logs = & $getLogBlock $Include $Exclude $MinRecordCount $AllLogs.IsPresent
            }
            else {
                $sessionParameters = @{ ComputerName = $computer; UseSSL = $UseSSL }
                if ($Credential) { $sessionParameters.Credential = $Credential }
                $session = New-PSSession @sessionParameters
                $logs = Invoke-Command -Session $session -ScriptBlock $getLogBlock -ArgumentList $Include, $Exclude, $MinRecordCount, $AllLogs.IsPresent
            }

            foreach ($log in $logs) {
                $archive = -not $SkipArchive -and $ArchivePath
                $action = if ($archive) { 'Archive and clear event log' } else { 'Clear event log' }
                $target = "$computer :: $($log.LogName)"
                if (-not $PSCmdlet.ShouldProcess($target, $action)) {
                    continue
                }

                $safeLogName = $log.LogName -replace '[\\/:*?"<>|]', '_'
                $fileName = '{0}_{1}_{2:yyyyMMdd_HHmmss}.evtx' -f $computer, $safeLogName, (Get-Date)
                $remoteBackupPath = $null
                if ($archive) {
                    $remoteBackupPath = if ($isLocal) {
                        $null = New-Item -ItemType Directory -Path $ArchivePath -Force
                        Join-Path $ArchivePath $fileName
                    }
                    else {
                        Join-Path $env:TEMP $fileName
                    }
                }

                try {
                    if ($isLocal) {
                        & $clearBlock $log.LogName $remoteBackupPath
                    }
                    else {
                        Invoke-Command -Session $session -ScriptBlock $clearBlock -ArgumentList $log.LogName, $remoteBackupPath
                        if ($archive) {
                            $null = New-Item -ItemType Directory -Path $ArchivePath -Force
                            Copy-Item -FromSession $session -LiteralPath $remoteBackupPath -Destination (Join-Path $ArchivePath $fileName) -Force
                            Invoke-Command -Session $session -ScriptBlock {
                                Remove-Item -LiteralPath $using:remoteBackupPath -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                    $summary.Add([pscustomobject]@{ ComputerName = $computer; LogName = $log.LogName; Cleared = $true; Error = $null })
                }
                catch {
                    $summary.Add([pscustomobject]@{ ComputerName = $computer; LogName = $log.LogName; Cleared = $false; Error = $_.Exception.Message })
                    Write-Error -ErrorRecord $_
                }
            }
        }
        finally {
            if ($session) { Remove-PSSession -Session $session }
        }
    }
}

end {
    $summary
}
