<#
.SYNOPSIS
    Lists running services or jobs on Windows, Linux, or macOS.
#>

#Requires -Version 7.0

[CmdletBinding()]
param()

if ($IsWindows) {
    Get-Service |
        Where-Object Status -EQ 'Running' |
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
    $launchOutput = @(& /bin/launchctl list 2>$null)
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'launchctl could not query the current session. This can occur in a restricted or non-GUI session.'
        return
    }

    $launchOutput | Select-Object -Skip 1 | ForEach-Object {
        $columns = $_ -split '\s+', 3
        if ($columns.Count -eq 3 -and $columns[0] -match '^\d+$') {
            [pscustomobject]@{ Platform = 'macOS'; Name = $columns[2]; DisplayName = $columns[2]; Status = 'Running'; ProcessId = [int]$columns[0] }
        }
    }
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}
