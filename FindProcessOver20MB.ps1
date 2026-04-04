<#
.SYNOPSIS
    Finds process over 20 mb.
#>

Get-Process | Where-Object {$_.WorkingSet -gt 20000000}