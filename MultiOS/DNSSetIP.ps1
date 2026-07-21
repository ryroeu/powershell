<#
.SYNOPSIS
    Sets DNS servers on selected network connections across supported platforms.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ipaddress[]]$ServerAddress,

    [string[]]$Interface,

    [switch]$FlushCache
)

if ($IsWindows) {
    $adapters = if ($Interface) {
        foreach ($name in $Interface) { Get-NetAdapter -Name $name -ErrorAction Stop }
    }
    else {
        Get-NetAdapter | Where-Object Status -eq 'Up'
    }
    foreach ($adapter in $adapters) {
        if ($PSCmdlet.ShouldProcess($adapter.Name, "Set DNS servers to '$($ServerAddress -join ', ')'")) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $ServerAddress.IPAddressToString -ErrorAction Stop
        }
    }
}
elseif ($IsMacOS) {
    if ([Environment]::UserName -ne 'root') { throw 'Run this script as root on macOS.' }
    if (-not $Interface) { throw 'Specify one or more network service names with -Interface on macOS.' }
    foreach ($service in $Interface) {
        if ($PSCmdlet.ShouldProcess($service, "Set DNS servers to '$($ServerAddress -join ', ')'")) {
            & /usr/sbin/networksetup -setdnsservers $service $ServerAddress.IPAddressToString
            if ($LASTEXITCODE -ne 0) { throw "networksetup failed with exit code $LASTEXITCODE for '$service'." }
        }
    }
}
elseif ($IsLinux) {
    if ([Environment]::UserName -ne 'root') { throw 'Run this script as root on Linux.' }
    if (Get-Command resolvectl -CommandType Application -ErrorAction SilentlyContinue) {
        if (-not $Interface) {
            $Interface = @((& ip route show default | Select-Object -First 1) -replace '^.*\sdev\s+(\S+).*$','$1')
        }
        foreach ($name in $Interface) {
            if ($PSCmdlet.ShouldProcess($name, "Set DNS servers to '$($ServerAddress -join ', ')'")) {
                & resolvectl dns $name $ServerAddress.IPAddressToString
                if ($LASTEXITCODE -ne 0) { throw "resolvectl failed with exit code $LASTEXITCODE for '$name'." }
            }
        }
    }
    elseif (Get-Command nmcli -CommandType Application -ErrorAction SilentlyContinue) {
        if (-not $Interface) { throw 'Specify NetworkManager connection names with -Interface.' }
        foreach ($connection in $Interface) {
            if ($PSCmdlet.ShouldProcess($connection, "Set DNS servers to '$($ServerAddress -join ', ')'")) {
                $ipv4 = @($ServerAddress | Where-Object AddressFamily -eq InterNetwork).IPAddressToString -join ','
                $ipv6 = @($ServerAddress | Where-Object AddressFamily -eq InterNetworkV6).IPAddressToString -join ','
                if ($ipv4) { & nmcli connection modify $connection ipv4.dns $ipv4 ipv4.ignore-auto-dns yes }
                if ($ipv6) { & nmcli connection modify $connection ipv6.dns $ipv6 ipv6.ignore-auto-dns yes }
                & nmcli connection up $connection
                if ($LASTEXITCODE -ne 0) { throw "nmcli failed with exit code $LASTEXITCODE for '$connection'." }
            }
        }
    }
    else {
        throw 'Neither resolvectl nor nmcli was found.'
    }
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}

if ($FlushCache) {
    & (Join-Path $PSScriptRoot 'DNSFlush.ps1') -Confirm:$false
}
