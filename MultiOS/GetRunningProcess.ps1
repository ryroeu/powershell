<#
.SYNOPSIS
    Lists running processes on Windows, Linux, or macOS.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string[]]$Name = @('*')
)

Get-Process -Name $Name -ErrorAction SilentlyContinue |
    Sort-Object ProcessName, Id |
    Select-Object Id, ProcessName, CPU, WorkingSet64, StartTime, Path
