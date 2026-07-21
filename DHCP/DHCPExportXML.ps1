<#
.SYNOPSIS
    Exports a Windows DHCP Server configuration and leases to XML.
#>

[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [string]$Path = (Join-Path $PWD 'DHCPConfig.xml'),

    [ipaddress[]]$ScopeId
)

$parameters = @{
    ComputerName = $ComputerName
    File         = $Path
    Leases       = $true
    Force        = $true
}
if ($ScopeId) {
    $parameters.ScopeId = $ScopeId
}

Export-DhcpServer @parameters
Get-Item -LiteralPath $Path
