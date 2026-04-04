#Requires -Version 7.0

<#
.SYNOPSIS
Detects the operating system and displays DNS server information accordingly.

.DESCRIPTION
This script checks if it's running on Windows, macOS, or Linux using built-in
PowerShell variables ($IsWindows, $IsMacOS, $IsLinux) available in PowerShell 7+.
It then executes the appropriate native command or cmdlet to show the configured
DNS servers for the system's active network interfaces.

.NOTES
Date:   2025-04-02
Requires PowerShell 7.0 or later for cross-platform OS detection variables.

On Linux, this script primarily checks /etc/resolv.conf. If your system uses
systemd-resolved, this file might only point to a local stub resolver (like 127.0.0.53).
In such cases, you might need to run 'resolvectl status' manually in a terminal
for more detailed information about the upstream DNS servers.

On macOS, 'scutil --dns' provides comprehensive DNS resolver information.

On Windows, 'Get-DnsClientServerAddress' retrieves DNS servers per interface.
#>

Write-Host "Detecting Operating System and fetching DNS information..." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------"

if ($IsWindows) {
    Write-Host "[+] Operating System: Windows" -ForegroundColor Green
    Write-Host "[+] Running 'Get-DnsClientServerAddress'..."
    Write-Host ""
    try {
        # Get DNS server addresses for active interfaces (IPv4 and IPv6)
        # Filter for interfaces that are UP and have DNS servers configured
        Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object {
            $adapter = $_
            $dnsInfo = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue
            if ($dnsInfo) {
                Write-Host "Interface: $($adapter.Name) ($($adapter.InterfaceDescription))"
                Write-Host "  Status: $($adapter.Status)"
                # Format addresses nicely, handling potential multiple addresses per family
                $ipv4Addresses = ($dnsInfo | Where-Object {$_.AddressFamily -eq 'InterNetwork'}).ServerAddresses -join ', '
                $ipv6Addresses = ($dnsInfo | Where-Object {$_.AddressFamily -eq 'InterNetworkV6'}).ServerAddresses -join ', '
                if ($ipv4Addresses) { Write-Host "  IPv4 DNS Servers: $ipv4Addresses" }
                if ($ipv6Addresses) { Write-Host "  IPv6 DNS Servers: $ipv6Addresses" }
                Write-Host ""
            }
        }
    } catch {
        Write-Warning "Error retrieving DNS information on Windows: $($_.Exception.Message)"
        Write-Host "You can also try running 'ipconfig /all' manually in Command Prompt or PowerShell."
    }

} elseif ($IsMacOS) {
    Write-Host "[+] Operating System: macOS" -ForegroundColor Green
    Write-Host "[+] Running 'scutil --dns'..."
    Write-Host ""
    try {
        # scutil provides detailed DNS configuration including resolvers and search domains
        scutil --dns
    } catch {
        Write-Warning "Error running 'scutil --dns' on macOS: $($_.Exception.Message)"
         Write-Host "You can also try running 'cat /etc/resolv.conf' manually in the Terminal."
   }

} elseif ($IsLinux) {
    Write-Host "[+] Operating System: Linux" -ForegroundColor Green
    Write-Host "[+] Displaying contents of '/etc/resolv.conf'..."
    Write-Host "[!] Note: If you see 127.0.0.53, your system likely uses a local DNS resolver (e.g., systemd-resolved)."
    Write-Host "[!]       Run 'resolvectl status' or 'nmcli dev show | grep DNS' manually for more details in that case."
    Write-Host ""
    $resolvConfPath = "/etc/resolv.conf"
    if (Test-Path $resolvConfPath) {
        try {
            Get-Content $resolvConfPath
        } catch {
             Write-Warning "Error reading '$resolvConfPath' on Linux: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "'$resolvConfPath' not found. Unable to determine DNS servers using this default method."
        Write-Host "Consider trying 'resolvectl status' (if using systemd-resolved)"
        Write-Host "or 'nmcli dev show | grep DNS' (if using NetworkManager) manually in your terminal."
    }

} else {
    Write-Error "Operating System: Unknown or Unsupported by this script."
    Write-Host "Could not determine the operating system type using \$IsWindows, \$IsMacOS, or \$IsLinux."
}

Write-Host "--------------------------------------------------------"
Write-Host "DNS information retrieval process complete." -ForegroundColor Yellow