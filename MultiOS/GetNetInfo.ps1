<#
.SYNOPSIS
    Cross-platform PowerShell script to gather network information.
.DESCRIPTION
    This script detects the OS (Windows, macOS, or Linux), retrieves local IP and subnet details,
    default gateway, public IP, calculates the CIDR and network address properly, and scans the network for active hosts.
.NOTES
    Tested on Windows, macOS, and Linux with PowerShell Core.
#>

param(
    [int]$PublicIPTimeoutSeconds = 5,
    [int]$PingTimeoutMilliseconds = 400,
    [int]$ThrottleLimit = 64,
    [int]$MaxHostsToScan = 512,
    [switch]$SkipHostScan
)

# OS Detection
if ($IsWindows) {
    $platform = "Windows"
}
elseif ($IsMacOS) {
    $platform = "macOS"
}
elseif ($IsLinux) {
    $platform = "Linux"
}
else {
    $platform = "Other"
}

# Function: Convert dotted-decimal netmask to CIDR prefix (Windows fallback)
function Get-CIDRFromMask ($mask) {
    $binaryMask = ($mask -split '\.') | ForEach-Object { [Convert]::ToString([int]$_, 2).PadLeft(8, '0') }
    return (($binaryMask -join '') -replace '0+$' ).Length
}

# Function: Convert hexadecimal netmask (macOS) to CIDR prefix
function Convert-HexNetmaskToPrefix {
    param(
        [string]$hexNetmask
    )
    $hex = $hexNetmask.Trim().TrimStart("0x")
    try {
        $intValue = [Convert]::ToUInt32($hex, 16)
    }
    catch {
        Write-Verbose "Conversion of netmask $hexNetmask failed."
        return 24  # fallback
    }
    $binary = [Convert]::ToString($intValue, 2).PadLeft(32, '0')
    $ones = ($binary.ToCharArray() | Where-Object { $_ -eq '1' }).Count
    return $ones
}

# Function: Convert IPv4 string to UInt32 for bitwise operations
function Convert-IPv4ToUInt32 {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress
    )

    $parsedAddress = [System.Net.IPAddress]::Parse($IPAddress)
    if ($parsedAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
        throw "Invalid IPv4 address: $IPAddress"
    }

    $bytes = $parsedAddress.GetAddressBytes()
    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($bytes)
    }

    return [BitConverter]::ToUInt32($bytes, 0)
}

# Function: Convert UInt32 back to IPv4 dotted-decimal notation
function Convert-UInt32ToIPv4 {
    param(
        [Parameter(Mandatory)]
        [uint32]$Address
    )

    $bytes = [BitConverter]::GetBytes($Address)
    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($bytes)
    }

    return ([System.Net.IPAddress]::new($bytes)).ToString()
}

# Function: Get local IP and Subnet mask/prefix
function Get-LocalIPInfo {
    if ($platform -eq "Windows") {
        Write-Verbose "Attempting to retrieve IP using Get-NetIPAddress..."
        try {
            $ipObj = Get-NetIPAddress -AddressFamily IPv4 |
                Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.IPAddress -notmatch ':' } |
                Select-Object -First 1
        }
        catch {
            Write-Verbose "Get-NetIPAddress failed: $_"
        }
        if ($ipObj) {
            Write-Verbose "IP retrieved via Get-NetIPAddress: $($ipObj.IPAddress)"
            return [PSCustomObject]@{
                IP     = $ipObj.IPAddress
                Subnet = $ipObj.PrefixLength  # Already in CIDR form.
            }
        }
        Write-Verbose "Falling back to Get-CimInstance..."
        try {
            $ipConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
                Where-Object { $_.IPAddress -and $_.IPAddress[0] -ne "127.0.0.1" } |
                Select-Object -First 1
        }
        catch {
            Write-Verbose "Get-CimInstance failed: $_"
        }
        if ($ipConfig -and $ipConfig.IPAddress[0] -and $ipConfig.IPSubnet[0]) {
            $subnetPrefix = Get-CIDRFromMask $ipConfig.IPSubnet[0]
            Write-Verbose "IP retrieved via Get-CimInstance: $($ipConfig.IPAddress[0])"
            return [PSCustomObject]@{
                IP     = $ipConfig.IPAddress[0]
                Subnet = $subnetPrefix
            }
        }
        Write-Verbose "Falling back to parsing ipconfig output..."
        $ipInfo = ipconfig 2>$null | Select-String -Pattern 'IPv4 Address|Subnet Mask'
        $localIP = ""
        $subnetMask = ""
        foreach ($line in $ipInfo) {
            if ($line -match 'IPv4 Address.*:\s*([\d\.]+)') {
                $localIP = $Matches[1]
            }
            elseif ($line -match 'Subnet Mask.*:\s*([\d\.]+)') {
                $subnetMask = $Matches[1]
            }
        }
        if ($localIP) {
            $prefix = if ($subnetMask) { Get-CIDRFromMask $subnetMask } else { 24 }
            Write-Verbose "IP retrieved via ipconfig parsing: $localIP"
            return [PSCustomObject]@{
                IP     = $localIP
                Subnet = $prefix
            }
        }
    }
    elseif ($platform -eq "macOS") {
        Write-Verbose "Attempting to retrieve IP using ifconfig on macOS..."
        $ifconfigOutput = ifconfig 2>$null
        # Look for an active non-loopback interface (commonly en0)
        $ipLine = $ifconfigOutput | Select-String -Pattern 'inet ' | Where-Object { $_ -notmatch '127.0.0.1' } | Select-Object -First 1
        if ($ipLine -match 'inet\s+([\d\.]+)\s+netmask\s+(0x[0-9a-fA-F]+)') {
            $ip = $Matches[1]
            $netmaskHex = $Matches[2]
            $prefix = Convert-HexNetmaskToPrefix $netmaskHex
            Write-Verbose "IP retrieved via ifconfig: $ip with prefix $prefix"
            return [PSCustomObject]@{
                IP     = $ip
                Subnet = $prefix
            }
        }
        else {
            Write-Verbose "Failed to parse ifconfig output."
        }
    }
    elseif ($platform -eq "Linux") {
        Write-Verbose "Attempting to retrieve IP using 'ip' command on Linux..."
        $ipMatch = ip -4 addr show | Select-String -Pattern "inet " | Where-Object { $_ -notmatch "127.0.0.1" } | Select-Object -First 1
        if ($null -ne $ipMatch -and $ipMatch.ToString() -match 'inet\s+([\d\.]+)/(\d+)') {
            Write-Verbose "IP retrieved via ip command: $($Matches[1])"
            return [PSCustomObject]@{
                IP     = $Matches[1]
                Subnet = [int]$Matches[2]
            }
        }
        else {
            Write-Warning "Unable to determine IP information on Linux."
            return $null
        }
    }
    Write-Verbose "No IP information could be retrieved."
    return $null
}

$ipInfoObj = Get-LocalIPInfo
if (-not $ipInfoObj) {
    Write-Error "Failed to retrieve local IP information."
    exit 1
}
$localIP = $ipInfoObj.IP
$cidrPrefix = $ipInfoObj.Subnet

# Function: Compute network address from IP and CIDR prefix
function Get-NetworkAddress($ip, $prefix) {
    $ipInt = Convert-IPv4ToUInt32 -IPAddress $ip
    $mask = if ($prefix -eq 0) { [uint32]0 } else { [uint32]([uint32]::MaxValue -shl (32 - $prefix)) }
    $networkInt = $ipInt -band $mask
    return (Convert-UInt32ToIPv4 -Address $networkInt)
}

$networkAddress = Get-NetworkAddress $localIP $cidrPrefix
$subnetCIDR = "$networkAddress/$cidrPrefix"

# Function: Get Default Gateway
function Get-DefaultGateway {
    if ($platform -eq "Windows") {
        try {
            $gw = Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
                Sort-Object -Property RouteMetric |
                Select-Object -First 1 -ExpandProperty NextHop
        }
        catch {
            $gw = "Unavailable"
        }
    }
    elseif ($platform -eq "macOS") {
        try {
            # On macOS, use netstat to retrieve the default gateway.
            $gwLine = netstat -rn | Select-String -Pattern '^default' | Select-Object -First 1
            if ($gwLine -match '^default\s+([\d\.]+)') {
                $gw = $Matches[1]
            }
            else {
                $gw = "Unavailable"
            }
        }
        catch {
            $gw = "Unavailable"
        }
    }
    elseif ($platform -eq "Linux") {
        try {
            $gwLine = (ip route show default | Select-String -Pattern "^default") -split " "
            $gw = $gwLine[2]
        }
        catch {
            $gw = "Unavailable"
        }
    }
    else {
        $gw = "Unavailable"
    }
    return $gw
}
$routerLocalIP = Get-DefaultGateway

# Get public IP address (external IP of router)
try {
    $routerPublicIP = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec $PublicIPTimeoutSeconds
}
catch {
    $routerPublicIP = "Unavailable"
}

# Function: Build the host list for a CIDR subnet
function Get-HostScanTarget {
    param(
        [Parameter(Mandatory)]
        [string]$NetworkAddress,

        [Parameter(Mandatory)]
        [int]$Prefix,

        [Parameter(Mandatory)]
        [string]$LocalIPAddress,

        [Parameter(Mandatory)]
        [int]$MaximumHosts
    )

    if ($Prefix -ge 31) {
        Write-Warning "Subnet /$Prefix does not provide a standard host range to scan."
        return @()
    }

    $hostBits = 32 - $Prefix
    $usableHosts = [int64]([math]::Pow(2, $hostBits) - 2)

    if ($usableHosts -gt $MaximumHosts) {
        Write-Warning "Skipping host scan for $NetworkAddress/$Prefix because it contains $usableHosts hosts, which exceeds the limit of $MaximumHosts."
        return $null
    }

    $networkInt = Convert-IPv4ToUInt32 -IPAddress $NetworkAddress
    $broadcastInt = $networkInt + [uint32]([math]::Pow(2, $hostBits) - 1)
    $targets = New-Object System.Collections.Generic.List[string]

    for ($address = $networkInt + 1; $address -lt $broadcastInt; $address++) {
        $target = Convert-UInt32ToIPv4 -Address $address
        if ($target -ne $LocalIPAddress) {
            $targets.Add($target)
        }
    }

    return $targets.ToArray()
}

# Function: Test if a host responds to ICMP without long blocking waits
function Test-HostReachable {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,

        [int]$TimeoutMilliseconds
    )

    $ping = [System.Net.NetworkInformation.Ping]::new()
    try {
        $reply = $ping.Send($IPAddress, $TimeoutMilliseconds)
        return $reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success
    }
    catch {
        return $false
    }
    finally {
        $ping.Dispose()
    }
}

# Function: Detect whether ICMP probing is available on this system/network
function Test-PingCapability {
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,

        [int]$TimeoutMilliseconds
    )

    $ping = [System.Net.NetworkInformation.Ping]::new()
    try {
        $null = $ping.Send($IPAddress, [Math]::Max($TimeoutMilliseconds, 250))
        return $true
    }
    catch {
        return $false
    }
    finally {
        $ping.Dispose()
    }
}

# Function: Discover active hosts on the network
function Get-ActiveHost {
    param(
        [bool]$Skip,
        [int]$MaximumHosts,
        [int]$TimeoutMilliseconds,
        [int]$ParallelThrottleLimit
    )

    if ($Skip) {
        return "Skipped"
    }

    $targets = Get-HostScanTarget -NetworkAddress $networkAddress -Prefix $cidrPrefix -LocalIPAddress $localIP -MaximumHosts $MaximumHosts
    if ($null -eq $targets) {
        return "Skipped"
    }

    if ($targets.Count -eq 0) {
        return 0
    }

    $probeTarget = if ($routerLocalIP -and $routerLocalIP -ne "Unavailable") { $routerLocalIP } else { $targets[0] }
    if (-not (Test-PingCapability -IPAddress $probeTarget -TimeoutMilliseconds $TimeoutMilliseconds)) {
        Write-Warning "ICMP probing is unavailable on this system or network; host scan skipped."
        return "Unavailable"
    }

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $activeHosts = $targets | ForEach-Object -Parallel {
            $ping = [System.Net.NetworkInformation.Ping]::new()
            try {
                $reply = $ping.Send($_, $using:TimeoutMilliseconds)
                if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                    $_
                }
            }
            catch {
                Write-Verbose "Ping to '$_' failed."
            }
            finally {
                $ping.Dispose()
            }
        } -ThrottleLimit $ParallelThrottleLimit

        return @($activeHosts).Count
    }

    $activeCount = 0
    foreach ($target in $targets) {
        if (Test-HostReachable -IPAddress $target -TimeoutMilliseconds $TimeoutMilliseconds) {
            $activeCount++
        }
    }

    return $activeCount
}
$deviceCount = Get-ActiveHost -Skip $SkipHostScan -MaximumHosts $MaxHostsToScan -TimeoutMilliseconds $PingTimeoutMilliseconds -ParallelThrottleLimit $ThrottleLimit

# Output results
$result = [PSCustomObject]@{
    "Local Device IP"            = $localIP
    "Network (CIDR)"             = $subnetCIDR
    "Default Gateway (Local IP)" = $routerLocalIP
    "Public IP of Router"        = $routerPublicIP
    "Active Devices on Network"  = $deviceCount
}

$result #| Format-Table -AutoSize
