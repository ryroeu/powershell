<#
.SYNOPSIS
    Sets time zone remotely.
#>

$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
Invoke-Command -ComputerName $computers -ScriptBlock {TZUTIL /s "Hawaiian Standard Time"}