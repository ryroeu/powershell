<#
.SYNOPSIS
    Registers DNS flush.
#>

ipconfig /flushdns
Start-Sleep 1
ipconfig /registerdns