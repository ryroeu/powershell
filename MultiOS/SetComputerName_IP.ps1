<#
.SYNOPSIS
    Sets the host name and a static IPv4 configuration on Windows, Linux, or macOS.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$NewComputerName,

    [Parameter(Mandatory)]
    [ipaddress]$IPAddress,

    [Parameter(Mandatory)]
    [ValidateRange(0, 32)]
    [int]$PrefixLength,

    [Parameter(Mandatory)]
    [ipaddress]$Gateway,

    [Parameter(Mandatory)]
    [ipaddress[]]$DnsServer,

    [Parameter(Mandatory)]
    [string]$InterfaceName,

    [switch]$Restart
)

if ($IPAddress.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork -or
    $Gateway.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
    throw 'IPAddress and Gateway must be IPv4 addresses.'
}

if ($IsWindows) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Rename to '$NewComputerName'")) {
        Rename-Computer -NewName $NewComputerName -Force -Restart:$false -ErrorAction Stop
    }
    if ($PSCmdlet.ShouldProcess($InterfaceName, "Set $IPAddress/$PrefixLength with gateway $Gateway")) {
        New-NetIPAddress -InterfaceAlias $InterfaceName -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $Gateway -ErrorAction Stop
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceName -ServerAddresses $DnsServer.IPAddressToString -ErrorAction Stop
    }
    if ($Restart -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Restart computer')) {
        Restart-Computer -Force
    }
}
elseif ($IsLinux) {
    if ([Environment]::UserName -ne 'root') { throw 'Run this script as root on Linux.' }
    foreach ($command in 'hostnamectl', 'nmcli') {
        if (-not (Get-Command $command -CommandType Application -ErrorAction SilentlyContinue)) { throw "'$command' was not found." }
    }
    if ($PSCmdlet.ShouldProcess([Environment]::MachineName, "Rename to '$NewComputerName'")) {
        & hostnamectl set-hostname $NewComputerName
        if ($LASTEXITCODE -ne 0) { throw "hostnamectl failed with exit code $LASTEXITCODE." }
    }
    if ($PSCmdlet.ShouldProcess($InterfaceName, "Set $IPAddress/$PrefixLength with gateway $Gateway")) {
        & nmcli connection modify $InterfaceName ipv4.addresses "$IPAddress/$PrefixLength" ipv4.gateway $Gateway.IPAddressToString ipv4.dns ($DnsServer.IPAddressToString -join ',') ipv4.method manual
        if ($LASTEXITCODE -ne 0) { throw "nmcli modify failed with exit code $LASTEXITCODE." }
        & nmcli connection up $InterfaceName
        if ($LASTEXITCODE -ne 0) { throw "nmcli activation failed with exit code $LASTEXITCODE." }
    }
    if ($Restart -and $PSCmdlet.ShouldProcess([Environment]::MachineName, 'Restart computer')) {
        & shutdown -r now
    }
}
elseif ($IsMacOS) {
    if ([Environment]::UserName -ne 'root') { throw 'Run this script as root on macOS.' }
    $maskOctets = for ($octet = 0; $octet -lt 4; $octet++) {
        $bits = [Math]::Clamp($PrefixLength - ($octet * 8), 0, 8)
        if ($bits -eq 0) { 0 } else { 256 - [Math]::Pow(2, 8 - $bits) }
    }
    $subnetMask = $maskOctets -join '.'
    if ($PSCmdlet.ShouldProcess([Environment]::MachineName, "Rename to '$NewComputerName'")) {
        foreach ($nameType in 'ComputerName', 'HostName', 'LocalHostName') {
            & /usr/sbin/scutil --set $nameType $NewComputerName
            if ($LASTEXITCODE -ne 0) { throw "scutil failed with exit code $LASTEXITCODE for '$nameType'." }
        }
    }
    if ($PSCmdlet.ShouldProcess($InterfaceName, "Set $IPAddress/$PrefixLength with gateway $Gateway")) {
        & /usr/sbin/networksetup -setmanual $InterfaceName $IPAddress.IPAddressToString $subnetMask $Gateway.IPAddressToString
        if ($LASTEXITCODE -ne 0) { throw "networksetup failed with exit code $LASTEXITCODE." }
        & /usr/sbin/networksetup -setdnsservers $InterfaceName $DnsServer.IPAddressToString
        if ($LASTEXITCODE -ne 0) { throw "networksetup DNS configuration failed with exit code $LASTEXITCODE." }
    }
    if ($Restart -and $PSCmdlet.ShouldProcess([Environment]::MachineName, 'Restart computer')) {
        & /sbin/shutdown -r now
    }
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}

[pscustomobject]@{
    ComputerName  = $NewComputerName
    InterfaceName = $InterfaceName
    IPAddress     = $IPAddress
    PrefixLength  = $PrefixLength
    Gateway       = $Gateway
    DnsServer     = $DnsServer
    Restart       = $Restart.IsPresent
}
