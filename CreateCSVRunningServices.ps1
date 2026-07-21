<#
.SYNOPSIS
    Exports running services to CSV.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path $PWD 'RunningServices.csv')
)

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    $null = New-Item -ItemType Directory -Path $parent -Force
}

Get-Service |
    Where-Object Status -eq 'Running' |
    Select-Object Name, DisplayName, Status, StartType |
    Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8
