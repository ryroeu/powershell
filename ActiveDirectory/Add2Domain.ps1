<#
.SYNOPSIS
    Adds 2 domain.
#>

Add-Computer -DomainName domain.com
Start-Sleep 30
Restart-Computer