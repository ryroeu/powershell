<#
.SYNOPSIS
    Reports TLS behavior for PowerShell 7 network cmdlets.
.DESCRIPTION
    PowerShell 7 uses System.Net.Http and the operating system TLS defaults. Forcing
    ServicePointManager.SecurityProtocol is a Windows PowerShell 5.1 workaround and does not
    configure Invoke-WebRequest or Invoke-RestMethod in current PowerShell.
#>

#Requires -Version 7.0

[CmdletBinding()]
param()

[pscustomobject]@{
    PowerShellVersion = $PSVersionTable.PSVersion
    HttpStack         = 'System.Net.Http.HttpClient'
    TlsConfiguration  = 'Operating-system defaults (TLS 1.2/1.3 where enabled)'
    Changed           = $false
}
