<#
.SYNOPSIS
    Reports configured DNS servers on Windows, Linux, or macOS.
#>

#Requires -Version 7.0

[CmdletBinding()]
param()

if ($IsWindows) {
    Get-DnsClientServerAddress | ForEach-Object {
        foreach ($address in $_.ServerAddresses) {
            [pscustomobject]@{
                Platform       = 'Windows'
                Interface      = $_.InterfaceAlias
                InterfaceIndex = $_.InterfaceIndex
                AddressFamily  = $_.AddressFamily
                ServerAddress  = $address
            }
        }
    }
}
elseif ($IsLinux) {
    if (Get-Command resolvectl -CommandType Application -ErrorAction SilentlyContinue) {
        & resolvectl dns --no-pager | ForEach-Object {
            if ($_ -match '^(?<Interface>\S+):\s*(?<Servers>.*)$') {
                foreach ($address in $Matches.Servers -split '\s+' | Where-Object { $_ }) {
                    [pscustomobject]@{ Platform = 'Linux'; Interface = $Matches.Interface; InterfaceIndex = $null; AddressFamily = $null; ServerAddress = $address }
                }
            }
        }
    }
    else {
        Get-Content -LiteralPath /etc/resolv.conf | ForEach-Object {
            if ($_ -match '^\s*nameserver\s+(?<Address>\S+)') {
                [pscustomobject]@{ Platform = 'Linux'; Interface = 'resolv.conf'; InterfaceIndex = $null; AddressFamily = $null; ServerAddress = $Matches.Address }
            }
        }
    }
}
elseif ($IsMacOS) {
    $resolver = $null
    $dnsServers = @(& /usr/sbin/scutil --dns 2>$null | ForEach-Object {
        if ($_ -match '^resolver #(?<Number>\d+)') { $resolver = "resolver-$($Matches.Number)" }
        elseif ($_ -match '^\s*nameserver\[\d+\]\s*:\s*(?<Address>\S+)') {
            [pscustomobject]@{ Platform = 'macOS'; Interface = $resolver; InterfaceIndex = $null; AddressFamily = $null; ServerAddress = $Matches.Address }
        }
    })

    if ($dnsServers.Count -eq 0 -and (Test-Path -LiteralPath /etc/resolv.conf)) {
        $dnsServers = @(Get-Content -LiteralPath /etc/resolv.conf | ForEach-Object {
            if ($_ -match '^\s*nameserver\s+(?<Address>\S+)') {
                [pscustomobject]@{ Platform = 'macOS'; Interface = 'resolv.conf'; InterfaceIndex = $null; AddressFamily = $null; ServerAddress = $Matches.Address }
            }
        })
    }

    $dnsServers
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}
