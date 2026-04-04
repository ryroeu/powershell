<#
.SYNOPSIS
    Stops get process.
#>

Get-Process ProcessName | Stop Process -force
Read-Host -Prompt "Press Enter to exit"