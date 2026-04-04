<#
.SYNOPSIS
    Sets the computer name (hostname) and configures a static IP address on Windows, macOS, or Linux.

.DESCRIPTION
    This script accepts parameters for a new computer name, an IP address, subnet mask (in dotted-decimal notation), gateway, and one or more DNS server addresses.
    It then detects the operating system and runs the appropriate commands:
      • Windows: Uses built-in cmdlets (Rename-Computer, New-NetIPAddress, Set-DnsClientServerAddress).
      • Linux: Uses sudo with hostnamectl and nmcli (requires NetworkManager).
      • macOS: Uses sudo with scutil and networksetup.
    You can optionally specify the network interface name. If not provided, the script uses a default value for each OS.

.PARAMETER ComputerName
    The new computer name/hostname.

.PARAMETER IPAddress
    The static IP address to set.

.PARAMETER SubnetMask
    The subnet mask in dotted-decimal notation (e.g., 255.255.255.0).

.PARAMETER Gateway
    The default gateway address.

.PARAMETER DNS
    One or more DNS server addresses.

.PARAMETER InterfaceName
    (Optional) The network interface name. Defaults are:
      - Windows: "Ethernet"
      - Linux: "eth0"
      - macOS: "Wi-Fi"

.EXAMPLE
    .\SetComputerNameAndIP.ps1 -ComputerName "MyComputer" -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1" -DNS "8.8.8.8","8.8.4.4"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ComputerName,

    [Parameter(Mandatory=$true)]
    [string]$IPAddress,

    [Parameter(Mandatory=$true)]
    [string]$SubnetMask,

    [Parameter(Mandatory=$true)]
    [string]$Gateway,

    [Parameter(Mandatory=$true)]
    [string[]]$DNS,

    [Parameter(Mandatory=$false)]
    [string]$InterfaceName
)

# Helper function to convert a dotted-decimal subnet mask to prefix length (e.g. "255.255.255.0" => 24)
function ConvertTo-PrefixLength {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SubnetMask
    )
    $octets = $SubnetMask.Split('.')
    if ($octets.Count -ne 4) {
        Write-Error "Invalid Subnet Mask format."
        exit 1
    }
    $binary = $octets | ForEach-Object { [Convert]::ToString([int]$_,2).PadLeft(8,'0') }
    $ones = ($binary -join "" | Select-String -Pattern "1").Matches.Count
    return $ones
}

# Calculate prefix length (used for Windows and Linux)
$prefixLength = ConvertTo-PrefixLength -SubnetMask $SubnetMask

if ($IsWindows) {
    Write-Host "Operating System: Windows" -ForegroundColor Green

    # Set the computer name
    try {
        Rename-Computer -NewName $ComputerName -Force -ErrorAction Stop
        Write-Host "Computer name set to $ComputerName. A restart may be required for the change to take effect." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to rename computer: $_"
    }

    # Use default interface if not provided
    if (-not $InterfaceName) { $InterfaceName = "Ethernet" }

    # Configure the static IP address
    try {
        New-NetIPAddress -InterfaceAlias $InterfaceName -IPAddress $IPAddress -PrefixLength $prefixLength -DefaultGateway $Gateway -ErrorAction Stop
        Write-Host "IP address $IPAddress configured on interface $InterfaceName." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set IP address: $_"
    }

    # Set DNS server addresses
    try {
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceName -ServerAddresses $DNS -ErrorAction Stop
        Write-Host "DNS servers set to $($DNS -join ', ')." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set DNS servers: $_"
    }

}
elseif ($IsLinux) {
    Write-Host "Operating System: Linux" -ForegroundColor Green

    # Set hostname
    try {
        sudo hostnamectl set-hostname $ComputerName
        Write-Host "Hostname set to $ComputerName." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set hostname: $_"
    }

    # Use default interface if not provided
    if (-not $InterfaceName) { $InterfaceName = "eth0" }

    # Combine DNS servers into a comma-separated string for nmcli
    $dnsList = $DNS -join ","

    # Configure static IP address using nmcli (requires NetworkManager)
    try {
        sudo nmcli con mod "$InterfaceName" ipv4.addresses "$IPAddress/$prefixLength" ipv4.gateway $Gateway ipv4.dns "$dnsList" ipv4.method manual
        sudo nmcli con up "$InterfaceName"
        Write-Host "IP configuration applied on interface $InterfaceName." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to configure network settings: $_"
    }
}
elseif ($IsMacOS) {
    Write-Host "Operating System: macOS" -ForegroundColor Green

    # Set hostname
    try {
        sudo scutil --set HostName $ComputerName
        Write-Host "Hostname set to $ComputerName." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set hostname: $_"
    }

    # Use default interface if not provided
    if (-not $InterfaceName) { $InterfaceName = "Wi-Fi" }

    # Configure static IP address using networksetup
    try {
        sudo networksetup -setmanual $InterfaceName $IPAddress $SubnetMask $Gateway
        Write-Host "IP address $IPAddress configured on interface $InterfaceName." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set IP address: $_"
    }

    # Set DNS servers
    try {
        sudo networksetup -setdnsservers $InterfaceName $DNS
        Write-Host "DNS servers set to $($DNS -join ', ')." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to set DNS servers: $_"
    }
}
else {
    Write-Error "Unsupported operating system."
}