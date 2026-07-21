<#
.SYNOPSIS
    Exports DHCP server leases and configuration to XML.
#>

[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [Parameter(Mandatory)]
    [string]$Path,

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
