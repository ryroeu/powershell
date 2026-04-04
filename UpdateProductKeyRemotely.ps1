<#
.SYNOPSIS
    Updates product key remotely.
#>

$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
Invoke-Command -ComputerName $computers -ScriptBlock {slmgr /ipk 12345-12345-12345-12345-12345}