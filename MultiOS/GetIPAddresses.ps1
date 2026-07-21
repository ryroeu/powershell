<#
.SYNOPSIS
    Lists unicast IP addresses with cross-platform .NET APIs.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [ValidateSet('IPv4', 'IPv6', 'Both')]
    [string]$AddressFamily = 'Both',

    [switch]$IncludeLoopback,

    [switch]$IncludeDown
)

foreach ($interface in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
    if (-not $IncludeDown -and $interface.OperationalStatus -ne 'Up') { continue }
    if (-not $IncludeLoopback -and $interface.NetworkInterfaceType -eq 'Loopback') { continue }

    foreach ($addressInfo in $interface.GetIPProperties().UnicastAddresses) {
        $family = if ($addressInfo.Address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) { 'IPv4' } else { 'IPv6' }
        if ($AddressFamily -ne 'Both' -and $AddressFamily -ne $family) { continue }

        [pscustomobject]@{
            InterfaceName     = $interface.Name
            InterfaceType     = $interface.NetworkInterfaceType
            OperationalStatus = $interface.OperationalStatus
            AddressFamily     = $family
            IPAddress         = $addressInfo.Address.ToString()
            PrefixLength      = $addressInfo.PrefixLength
        }
    }
}
