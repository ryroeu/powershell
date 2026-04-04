<#
.SYNOPSIS
Sets the DNS servers for the primary/active network connection(s) on Windows, macOS, or Linux.

.DESCRIPTION
This script auto-detects the operating system it's running on.
It requires PowerShell 7+ for macOS and Linux compatibility.
It sets the primary IPv4 DNS server to 9.9.9.11 and the primary IPv6 DNS server to 2620:fe::11.
Requires Administrator privileges on Windows or sudo/root privileges on macOS/Linux.

.NOTES
- PowerShell 7 (or later) MUST be installed to run this script on macOS and Linux.
- Run this script with elevated privileges (Administrator/sudo).
- Windows: Affects all network adapters with Status 'Up' (excluding loopback).
- macOS: Attempts to find the primary network service (e.g., Wi-Fi, Ethernet) and configure it.
- Linux: Attempts to use 'resolvectl' (for systemd-resolved) for the default route interface.
           May not work on all Linux distributions or configurations (e.g., those using NetworkManager primarily without systemd-resolved integration, or older systems).

.LINK
Quad9 DNS: https://quad9.net/

.EXAMPLE
# On Windows (Run PowerShell as Administrator):
.\Set-CrossPlatformDns.ps1

# On macOS (Requires PowerShell 7+ installed):
sudo pwsh ./Set-CrossPlatformDns.ps1

# On Linux (Requires PowerShell 7+ installed):
sudo pwsh ./Set-CrossPlatformDns.ps1
#>

# --- Configuration ---
$ipv4Dns = "9.9.9.11"
$ipv6Dns = "2620:fe::11"
# --- End Configuration ---

# Function to check if running with elevated privileges
function Test-IsElevated {
    if ($IsWindows) {
        return ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } elseif ($IsLinux -or $IsMacOS) {
        # Check effective user ID. 0 is root.
        return $(id -u) -eq 0
    } else {
        return $false # Unsupported OS
    }
}

# --- Main Script ---
Write-Host "Starting DNS Configuration Script..."
Write-Host "Target DNS Servers: IPv4=$ipv4Dns, IPv6=$ipv6Dns"

# Check for elevated privileges
if (-not (Test-IsElevated)) {
    Write-Error "This script requires elevated privileges (Administrator/sudo/root) to modify network settings. Please run it again with the required permissions."
    exit 1
}

Write-Host "Detecting Operating System..."

if ($IsWindows) {
    # --- Windows ---
    Write-Host "Detected Windows."
    Write-Host "Attempting to set DNS for active non-loopback adapters..."

    try {
        # Get active, non-virtual, non-loopback adapters
        $adapters = Get-NetAdapter | Where-Object {
            $_.Status -eq 'Up' -and
            $_.MediaType -ne 'Loopback' -and
            $_.Virtual -ne $true # Often good to exclude virtual adapters like Hyper-V/VMware/VPNs unless intended
        }

        if ($adapters) {
            $successCount = 0
            foreach ($adapter in $adapters) {
                Write-Host "--> Configuring adapter: $($adapter.Name) (InterfaceIndex: $($adapter.InterfaceIndex))"
                try {
                    # Set both IPv4 and IPv6 DNS servers. This overwrites existing settings for this adapter.
                    Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ($ipv4Dns, $ipv6Dns) -ErrorAction Stop
                    Write-Host "    Successfully set DNS for $($adapter.Name)."
                    $successCount++
                } catch {
                    Write-Warning "    Failed to set DNS for adapter '$($adapter.Name)'. Error: $($_.Exception.Message)"
                }
            }

            if ($successCount -gt 0) {
                 Write-Host "Windows DNS configuration applied to $successCount adapter(s)."
                 # Flush DNS cache
                 Write-Host "Flushing DNS cache..."
                 try {
                    ipconfig /flushdns | Out-Null
                    Write-Host "Windows DNS cache flushed."
                 } catch {
                    Write-Warning "Could not flush Windows DNS cache. Error: $($_.Exception.Message)"
                 }
            } else {
                 Write-Warning "DNS configuration failed for all detected active adapters."
            }

        } else {
            Write-Warning "No active, non-virtual, non-loopback network adapters found."
        }
    } catch {
        Write-Error "An error occurred during Windows DNS configuration: $($_.Exception.Message)"
    }

} elseif ($IsMacOS) {
    # --- macOS ---
    Write-Host "Detected macOS."
    Write-Host "Attempting to find and configure the primary network service..."

    # Check for required command
    $networksetupPath = Get-Command networksetup -ErrorAction SilentlyContinue
    if (-not $networksetupPath) {
        Write-Error "'networksetup' command not found. Cannot configure DNS on macOS."
        exit 1
    }

    try {
        # Try to find the primary network service (usually the first one listed that's connected)
        # This parsing might need adjustment based on specific macOS versions/outputs
        Write-Host "Finding primary network service..."
        $primaryService = $null
        # Get services and check their status one by one, starting from the top of the service order
        $services = (& $networksetupPath -listnetworkserviceorder | Where-Object {$_ -match '^\(Hardware Port:'}) | ForEach-Object { ($_ -split ': ')[1].Split(',')[0].Trim() }
        foreach ($service in $services) {
             # Check if the service is connected (has an IP) - This is a heuristic
             $ipInfo = & $networksetupPath -getinfo "$service"
             if ($ipInfo -match 'IP address:' -and $ipInfo -notmatch 'IP address: none') {
                 Write-Host "    Found active service: $service"
                 $primaryService = $service
                 break # Use the first active one found in order
             }
        }

        if ($primaryService) {
             Write-Host "--> Configuring service: $primaryService"
             try {
                # Set DNS servers (overwrites existing)
                & $networksetupPath -setdnsservers "$primaryService" $ipv4Dns $ipv6Dns
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "    Successfully set DNS for service '$primaryService'."

                    # Flush DNS cache
                    Write-Host "Flushing DNS cache..."
                    try {
                        & dscacheutil -flushcache
                        & killall -HUP mDNSResponder # Notify system of changes
                        Write-Host "macOS DNS cache flushed."
                    } catch {
                         Write-Warning "    Could not flush macOS DNS cache. Error: $($_.Exception.Message) (Exit Code: $LASTEXITCODE)"
                    }
                } else {
                    Write-Error "    'networksetup -setdnsservers' command failed for service '$primaryService' with exit code $LASTEXITCODE."
                }
             } catch {
                 Write-Error "    An error occurred calling networksetup for '$primaryService'. Error: $($_.Exception.Message)"
             }
        } else {
            Write-Warning "Could not determine an active primary network service (e.g., Wi-Fi, Ethernet). Common services checked: $($services -join ', ')"
            Write-Warning "You may need to configure DNS manually via System Settings > Network."
        }
    } catch {
         Write-Error "An error occurred during macOS DNS configuration: $($_.Exception.Message)"
    }

} elseif ($IsLinux) {
    # --- Linux ---
    Write-Host "Detected Linux."
    Write-Host "Attempting to set DNS using 'resolvectl' (requires systemd-resolved)..."

    # Check for required commands
    $resolvectlPath = Get-Command resolvectl -ErrorAction SilentlyContinue
    $ipPath = Get-Command ip -ErrorAction SilentlyContinue

    if (-not $resolvectlPath) {
        Write-Warning "Command 'resolvectl' not found."
        Write-Warning "This script relies on systemd-resolved for Linux DNS configuration."
        Write-Warning "Falling back to attempt using 'nmcli' (requires NetworkManager)..."

        $nmcliPath = Get-Command nmcli -ErrorAction SilentlyContinue
        if (-not $nmcliPath) {
            Write-Error "Command 'nmcli' also not found."
            Write-Error "Cannot automatically configure DNS on this Linux distribution. Please configure manually."
            exit 1
        }

        # --- Linux (nmcli fallback) ---
        Write-Host "Attempting to set DNS using 'nmcli'..."
        try {
             # Find active connections
             # nmcli -g specifies terse output for specific fields NAME,DEVICE,STATE
             $activeConnections = (& $nmcliPath -t -f NAME,DEVICE,STATE connection show --active) | ForEach-Object {
                 $parts = $_ -split ':'
                 if ($parts[2] -eq 'activated') { # Check state is activated
                     @{Name = $parts[0]; Device = $parts[1]}
                 }
             }

             if ($activeConnections) {
                 $successCount = 0
                 foreach ($conn in $activeConnections) {
                    Write-Host "--> Configuring connection: $($conn.Name) (Device: $($conn.Device))"
                    try {
                        # Set DNS, overriding DHCP settings
                        & $nmcliPath connection modify "$($conn.Name)" ipv4.dns "$ipv4Dns" ipv6.dns "$ipv6Dns" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes -ErrorAction Stop
                        if ($LASTEXITCODE -ne 0) { throw "nmcli modify failed with code $LASTEXITCODE" }

                        # Re-apply the connection settings
                        Write-Host "    Applying changes by reactivating connection '$($conn.Name)'..."
                        & $nmcliPath connection up "$($conn.Name)"
                         if ($LASTEXITCODE -eq 0) {
                             Write-Host "    Successfully set DNS for connection '$($conn.Name)' via nmcli."
                             $successCount++
                         } else {
                              Write-Warning "    Failed to reactivate connection '$($conn.Name)' after setting DNS (Exit code: $LASTEXITCODE). Changes might not be active."
                         }
                    } catch {
                        Write-Warning "    Failed to configure DNS for connection '$($conn.Name)' using nmcli. Error: $($_.Exception.Message)"
                    }
                 }
                 if ($successCount -gt 0) {
                     Write-Host "Linux DNS configuration via nmcli applied to $successCount connection(s)."
                 } else {
                     Write-Warning "DNS configuration via nmcli failed for all detected active connections."
                 }
             } else {
                 Write-Warning "No active NetworkManager connections found."
             }

        } catch {
             Write-Error "An error occurred during Linux DNS configuration using nmcli: $($_.Exception.Message)"
        }

    } elseif (-not $ipPath) {
        Write-Error "Command 'ip' not found. Cannot determine default interface for resolvectl."
        Write-Error "Please configure DNS manually."
        exit 1
    } else {
        # --- Linux (resolvectl primary path) ---
        try {
            Write-Host "Finding default network interface using 'ip route'..."
            # Get the interface used for the default route (reliable method)
            $interfaceName = (& $ipPath -o -4 route get 1.1.1.1 | Select-Object -First 1 | ForEach-Object { ($_ -split 'dev\s+')[1].Split(' ')[0] })
            # Alternative: $interfaceName = (& $ipPath route | Where-Object { $_ -match '^default' } | Select-Object -First 1 | ForEach-Object { ($_ -split ' ')[4] })

            if ($interfaceName) {
                Write-Host "    Found default interface: $interfaceName"
                Write-Host "--> Configuring interface '$interfaceName' using 'resolvectl'..."

                try {
                    # Set DNS for the interface
                    & $resolvectlPath dns "$interfaceName" "$ipv4Dns" "$ipv6Dns"
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "    Successfully set DNS via resolvectl for interface '$interfaceName'."

                         # Set DNSSEC setting to 'allow-downgrade' or 'yes' for Quad9 Secure/blocklist
                         Write-Host "    Setting DNSSEC to 'allow-downgrade' for interface '$interfaceName' (recommended for Quad9)..."
                         & $resolvectlPath dnssec "$interfaceName" allow-downgrade # or 'yes'
                         if ($LASTEXITCODE -ne 0) {
                             Write-Warning "    Could not set DNSSEC setting via resolvectl (Exit Code: $LASTEXITCODE)."
                         }

                         # Flush Cache
                         Write-Host "Flushing DNS cache via resolvectl..."
                         & $resolvectlPath flush-caches
                         if ($LASTEXITCODE -eq 0) {
                             Write-Host "systemd-resolved cache flushed."
                         } else {
                             Write-Warning "    Could not flush systemd-resolved cache (Exit code: $LASTEXITCODE)."
                         }
                    } else {
                        Write-Error "    'resolvectl dns' command failed with exit code $LASTEXITCODE. Check permissions or systemd-resolved status."
                    }
                } catch {
                     Write-Error "    An error occurred calling resolvectl. Error: $($_.Exception.Message)"
                }

            } else {
                Write-Warning "Could not determine the default network interface using 'ip route'. Unable to set DNS automatically via resolvectl."
            }
        } catch {
            Write-Error "An error occurred during Linux DNS configuration using resolvectl: $($_.Exception.Message)"
        }
    }

} else {
    # --- Unsupported OS ---
    Write-Error "Unsupported Operating System detected."
    Write-Host "Operating system identifier variables:"
    Write-Host "`$IsWindows: $IsWindows"
    Write-Host "`$IsMacOS: $IsMacOS"
    Write-Host "`$IsLinux: $IsLinux"
    Write-Host "This script currently supports Windows, macOS (using networksetup), and Linux (using systemd-resolved/resolvectl or NetworkManager/nmcli)."
}

Write-Host "Script execution finished."