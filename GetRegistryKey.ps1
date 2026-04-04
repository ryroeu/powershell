<#
.SYNOPSIS
    Retrieves registry key.
#>

# Get Registry Key
Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUServer
