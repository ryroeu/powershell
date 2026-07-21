<#
.SYNOPSIS
    Lists running services or jobs on Windows, Linux, or macOS.
#>

#Requires -Version 7.0

[CmdletBinding()]
param()

if ($IsWindows) {
    Get-Service |
        Where-Object Status -eq 'Running' |
        Select-Object @{ Name = 'Platform'; Expression = { 'Windows' } }, Name, DisplayName, Status
}
elseif ($IsLinux) {
    if (Get-Command systemctl -CommandType Application -ErrorAction SilentlyContinue) {
        & systemctl list-units --type=service --state=running --no-legend --no-pager --plain |
            ForEach-Object {
                if ($_ -match '^\s*(?<Unit>\S+)\s+(?<Load>\S+)\s+(?<Active>\S+)\s+(?<Sub>\S+)\s*(?<Description>.*)$') {
                    [pscustomobject]@{
                        Platform    = 'Linux'
                        Name        = $Matches.Unit
                        DisplayName = $Matches.Description
                        Status      = $Matches.Sub
                    }
                }
            }
        if ($LASTEXITCODE -ne 0) { throw "systemctl failed with exit code $LASTEXITCODE." }
    }
    else {
        throw 'systemctl was not found; this script currently supports systemd-based Linux distributions.'
    }
}
elseif ($IsMacOS) {
    & launchctl list | Select-Object -Skip 1 | ForEach-Object {
        $columns = $_ -split '\s+', 3
        if ($columns.Count -eq 3 -and $columns[0] -match '^\d+$') {
            [pscustomobject]@{ Platform = 'macOS'; Name = $columns[2]; DisplayName = $columns[2]; Status = 'Running'; ProcessId = [int]$columns[0] }
        }
    }
    if ($LASTEXITCODE -ne 0) { throw "launchctl failed with exit code $LASTEXITCODE." }
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}
