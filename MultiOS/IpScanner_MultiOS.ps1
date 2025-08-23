<#
.SYNOPSIS
  Scans a local network subnet and displays IP addresses that are actively responding to a ping.
  This script is designed to be cross-platform and works on Windows, macOS, and Linux
  with PowerShell Core (version 6.0 or later).

.DESCRIPTION
  This script first determines the local machine's IP address and uses that to
  find the local network subnet. It then generates a range of IP addresses
  (from .1 to .254) and uses Test-Connection to send a single ping packet to each.
  If an IP address responds, it is considered active and is displayed to the console.

  The script uses a multithreaded approach with a "RunspacePool" to perform pings
  concurrently, which significantly speeds up the scanning process. This is much
  more efficient than pinging each IP address sequentially.
#>

# Requires PowerShell 6.0 or later for cross-platform support and features like ForEach-Object -Parallel.
# Check for PowerShell version and exit if it's too old.
if ($PSVersionTable.PSVersion.Major -lt 6) {
    Write-Host "This script requires PowerShell 6.0 or later. Please install PowerShell Core." -ForegroundColor Red
    exit
}

function Scan-Network {
    # Determine the local network adapter's IPv4 address.
    # Get-NetIPAddress is a Windows-specific cmdlet. Using if ($IsWindows) is necessary here.
    # On macOS and Linux, we use 'ip route' and standard string manipulation to get the IP.
    Write-Host "Determining local network IP address..." -ForegroundColor Green
    $localIP = ""

    if ($IsWindows) {
        $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch "127.0.0.1|169.254." } | Select-Object -ExpandProperty IPAddress)
        if (-not $localIP) {
            Write-Host "Could not find a valid IPv4 address on a network adapter." -ForegroundColor Red
            return
        }
    }
    elseif ($IsLinux) {
        $localIP = (ip route | Where-Object { $_ -like '*src*' } | Select-Object -First 1).Split()[8]
    }
    elseif ($IsMacOs) {
        # macOS uses ifconfig, which is deprecated but still works for this purpose.
        $localIP = (ifconfig | Where-Object { $_ -like '*inet*' -and $_ -notlike '*127.0.0.1*' -and $_ -notlike '*inet6*' } | Select-Object -First 1).Trim().Split()[1]
    }

    if (-not $localIP) {
        Write-Host "Could not determine local IP address. Please check your network connection." -ForegroundColor Red
        return
    }

    Write-Host "Found local IP: $localIP" -ForegroundColor Yellow

    # Extract the subnet prefix (e.g., "192.168.1").
    $subnetPrefix = ($localIP.Split('.') | Select-Object -First 3) -join '.'
    Write-Host "Scanning subnet: $subnetPrefix.1 to $subnetPrefix.254" -ForegroundColor Yellow

    # Create a list of all possible IP addresses to scan.
    $ipAddressesToScan = @()
    for ($i = 1; $i -le 254; $i++) {
        $ipAddressesToScan += "$subnetPrefix.$i"
    }

    Write-Host "Scanning for active hosts..." -ForegroundColor Green
    
    # Use Test-Connection with parallel processing to improve performance.
    # The output of the parallel block is collected directly in $activeHosts.
    $activeHosts = $ipAddressesToScan | ForEach-Object -ThrottleLimit 10 -Parallel {
        $ip = $_
        try {
            $testResult = Test-Connection -TargetName $ip -Count 1 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($testResult.Status -eq "Success") {
                [PSCustomObject]@{
                    IP = $ip
                    Hostname = $testResult.IPV4Address.HostName
                }
            }
        }
        catch {
            # Catch any errors from Test-Connection and ignore them.
        }
    }

    Write-Host ""
    Write-Host "Active hosts found:" -ForegroundColor Green
    Write-Host "--------------------" -ForegroundColor Green

    # Display the found IP addresses and hostnames.
    if ($activeHosts.Count -gt 0) {
        $activeHosts | ForEach-Object {
            Write-Host "IP: $($_.IP)"
            Write-Host "Hostname: $($_.Hostname)"
            Write-Host ""
        }
        Write-Host "Scan complete. Found $($activeHosts.Count) active hosts." -ForegroundColor Green
    }
    else {
        Write-Host "No active hosts found on the network." -ForegroundColor Red
    }
}

# Run the function
Scan-Network
