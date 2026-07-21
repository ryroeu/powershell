<#
.SYNOPSIS
    Scans an IPv4 CIDR range for hosts that answer ICMP echo requests.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string]$Cidr,

    [ValidateRange(1, 65536)]
    [int]$MaxHosts = 1024,

    [ValidateRange(1, 1024)]
    [int]$ThrottleLimit = 64,

    [ValidateRange(1, 10000)]
    [int]$TimeoutMilliseconds = 500,

    [switch]$ResolveDns
)

function ConvertTo-UInt32Address {
    param([Parameter(Mandatory)][ipaddress]$Address)
    if ($Address.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) { throw "'$Address' is not IPv4." }
    $bytes = $Address.GetAddressBytes()
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($bytes) }
    [BitConverter]::ToUInt32($bytes, 0)
}

function ConvertTo-IPv4Address {
    param([Parameter(Mandatory)][uint32]$Value)
    $bytes = [BitConverter]::GetBytes($Value)
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($bytes) }
    [ipaddress]::new($bytes)
}

if (-not $Cidr) {
    $addressInfo = [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
        Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } |
        ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
        Where-Object { $_.Address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork -and -not $_.Address.IsIPv6LinkLocal } |
        Select-Object -First 1
    if (-not $addressInfo) { throw 'No active non-loopback IPv4 address was found.' }
    $Cidr = "$($addressInfo.Address)/$($addressInfo.PrefixLength)"
}

if ($Cidr -notmatch '^(?<Address>[^/]+)/(?<Prefix>\d{1,2})$') { throw "Invalid CIDR '$Cidr'." }
$address = [ipaddress]$Matches.Address
$prefixLength = [int]$Matches.Prefix
if ($address.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork -or $prefixLength -notin 0..32) {
    throw "Invalid IPv4 CIDR '$Cidr'."
}

$addressValue = ConvertTo-UInt32Address $address
$mask = if ($prefixLength -eq 0) { [uint32]0 } else { [uint32]([uint32]::MaxValue -shl (32 - $prefixLength)) }
$networkValue = $addressValue -band $mask
$addressCount = [uint64][Math]::Pow(2, 32 - $prefixLength)
$firstValue = [uint64]$networkValue
$lastValue = $firstValue + $addressCount - 1
if ($prefixLength -le 30) {
    $firstValue++
    $lastValue--
}
$hostCount = $lastValue - $firstValue + 1
if ($hostCount -gt $MaxHosts) {
    throw "CIDR '$Cidr' contains $hostCount usable addresses, exceeding -MaxHosts $MaxHosts."
}

$targets = for ($value = $firstValue; $value -le $lastValue; $value++) {
    (ConvertTo-IPv4Address ([uint32]$value)).IPAddressToString
}

$targets | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
    $target = $_
    $ping = [Net.NetworkInformation.Ping]::new()
    try {
        try {
            $reply = $ping.Send($target, $using:TimeoutMilliseconds)
        }
        catch {
            Write-Verbose "Ping failed for $target`: $($_.Exception.Message)"
            return
        }
        if ($reply.Status -ne [Net.NetworkInformation.IPStatus]::Success) { return }
        $hostName = if ($using:ResolveDns) {
            try { [Net.Dns]::GetHostEntry($target).HostName } catch { $null }
        }
        else { $null }
        [pscustomobject]@{
            IPAddress       = $target
            HostName        = $hostName
            RoundtripTimeMs = $reply.RoundtripTime
            Status          = $reply.Status
        }
    }
    finally {
        $ping.Dispose()
    }
} | Sort-Object { [version]$_.IPAddress }
