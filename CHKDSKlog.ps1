<#
.SYNOPSIS
    Exports CHKDSK results written by Wininit to a text file.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path $PWD 'CHKDSKResults.txt'),

    [ValidateRange(1, [int]::MaxValue)]
    [int]$Newest = 20
)

$events = Get-WinEvent -FilterHashtable @{
    LogName      = 'Application'
    Id           = 1001
    ProviderName = 'Microsoft-Windows-Wininit'
} -MaxEvents $Newest

$events |
    Select-Object TimeCreated, Message |
    Format-List |
    Out-File -LiteralPath $OutputPath -Encoding utf8

$events
