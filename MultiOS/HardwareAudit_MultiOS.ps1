<#
.SYNOPSIS
   Retrieves hardware and OS information including CPU details, memory, and disk space.
.DESCRIPTION
   This cross‑platform script gathers:
      • Processor Name and Manufacturer
      • Number of physical processor cores
      • CPU L2 and L3 Cache sizes (in MB)
      • OS Name and Version
      • Total and available memory (in GB)
      • Total and available disk space (in GB)
   It uses CIM/WMI on Windows, lscpu/free on Linux, and sysctl/sw_vers on macOS.
.NOTES
   Requires PowerShell 7+ for cross‑platform support.
#>

# Initialize variables
$cpuName                = ""
$processorManufacturer  = ""
$numberOfCores          = ""
$cpuL2MB                = ""
$cpuL3MB                = ""
$osName                 = ""
$osVersion              = ""
$totalMemGB             = ""
$availMemGB             = ""
$totalDiskGB            = ""
$availDiskGB            = ""

if ($IsWindows) {
    # Windows implementation using CIM
    $cpu    = Get-CimInstance Win32_Processor | Select-Object -First 1
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $disks  = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

    $cpuName               = $cpu.Name
    $processorManufacturer = $cpu.Manufacturer
    $numberOfCores         = $cpu.NumberOfCores
    # L2 and L3 cache sizes are in KB; convert to MB
    $cpuL2MB               = if ($cpu.L2CacheSize) { [math]::Round($cpu.L2CacheSize / 1024, 2) } else { "N/A" }
    $cpuL3MB               = if ($cpu.L3CacheSize) { [math]::Round($cpu.L3CacheSize / 1024, 2) } else { "N/A" }

    $osName    = $osInfo.Caption
    $osVersion = $osInfo.Version
    # Memory: TotalVisibleMemorySize and FreePhysicalMemory are in kilobytes
    $totalMemGB = [math]::Round($osInfo.TotalVisibleMemorySize / 1024 / 1024, 2)
    $availMemGB = [math]::Round($osInfo.FreePhysicalMemory / 1024 / 1024, 2)

    # Disk: Sum sizes and free space for all fixed disks (DriveType=3)
    $totalDiskBytes = ($disks | Measure-Object -Property Size -Sum).Sum
    $freeDiskBytes  = ($disks | Measure-Object -Property FreeSpace -Sum).Sum
    $totalDiskGB    = [math]::Round($totalDiskBytes / 1GB, 2)
    $availDiskGB    = [math]::Round($freeDiskBytes / 1GB, 2)

} elseif ($IsLinux) {
    # Linux implementation using lscpu, free, and df
    $lscpuOutput = & lscpu 2>$null
    if ($lscpuOutput) {
        # Processor Name and Vendor
        $cpuName = ($lscpuOutput | Where-Object { $_ -match "Model name:" } |
                    ForEach-Object { ($_ -split ":\s+",2)[1] }).Trim()
        $processorManufacturer = ($lscpuOutput | Where-Object { $_ -match "Vendor ID:" } |
                    ForEach-Object { ($_ -split ":\s+",2)[1] }).Trim()

        # Calculate physical cores using "Socket(s)" and "Core(s) per socket"
        $socketsStr       = ($lscpuOutput | Where-Object { $_ -match "^Socket\(s\):" } |
                             ForEach-Object { ($_ -split ":\s+",2)[1] }).Trim()
        $coresPerSocketStr = ($lscpuOutput | Where-Object { $_ -match "Core\(s\) per socket:" } |
                             ForEach-Object { ($_ -split ":\s+",2)[1] }).Trim()
        if ($socketsStr -and $coresPerSocketStr) {
            $numberOfCores = [int]$socketsStr * [int]$coresPerSocketStr
        }
        else {
            # Fallback to logical core count
            $numberOfCores = (& nproc)
        }

        # L2 and L3 cache sizes (if available; usually in KB)
        $l2CacheLine = $lscpuOutput | Where-Object { $_ -match "L2 cache:" }
        if ($l2CacheLine) {
            $l2CacheKB = [regex]::Match($l2CacheLine, "\d+").Value
            $cpuL2MB   = [math]::Round($l2CacheKB / 1024, 2)
        }
        else {
            $cpuL2MB = "N/A"
        }

        $l3CacheLine = $lscpuOutput | Where-Object { $_ -match "L3 cache:" }
        if ($l3CacheLine) {
            $l3CacheKB = [regex]::Match($l3CacheLine, "\d+").Value
            $cpuL3MB   = [math]::Round($l3CacheKB / 1024, 2)
        }
        else {
            $cpuL3MB = "N/A"
        }
    }
    else {
        $cpuName = "N/A"
        $processorManufacturer = "N/A"
        $numberOfCores = "N/A"
        $cpuL2MB = "N/A"
        $cpuL3MB = "N/A"
    }

    # OS Information: Try /etc/os-release for a pretty name; fallback to uname
    if (Test-Path /etc/os-release) {
        $osReleaseLine = Get-Content /etc/os-release | Where-Object { $_ -match "^PRETTY_NAME=" }
        $osName = $osReleaseLine -replace '^PRETTY_NAME="', '' -replace '"',''
    }
    else {
        $osName = (& uname -s).Trim()
    }
    $osVersion = (& uname -r).Trim()

    # Memory: Use free command (-m gives MB)
    $freeOutput = & free -m
    $freeLines = $freeOutput -split "`n"
    $memLine = $freeLines | Where-Object { $_ -match "^Mem:" }
    $memParts = $memLine -split "\s+"
    # Total memory is column 2; available memory is usually column 7
    $totalMemGB = [math]::Round([double]$memParts[1] / 1024, 2)
    $availMemGB = [math]::Round([double]$memParts[6] / 1024, 2)

    # Disk: Use df for the root filesystem (assumes output in GB with -BG flag)
    $dfOutput = & df -BG /
    $dfLines = $dfOutput -split "`n"
    if ($dfLines.Length -ge 2) {
        $diskParts = $dfLines[1] -split "\s+"
        # diskParts[1] is total size; diskParts[3] is available space
        $totalDiskGB = [regex]::Match($diskParts[1], "\d+").Value
        $availDiskGB = [regex]::Match($diskParts[3], "\d+").Value
    }
    else {
        $totalDiskGB = "N/A"
        $availDiskGB = "N/A"
    }

} elseif ($IsMacOS) {
    # macOS implementation using sysctl, sw_vers, and vm_stat
    $cpuName = (& sysctl -n machdep.cpu.brand_string).Trim()
    # Attempt to determine manufacturer from the CPU name string
    if ($cpuName -match "Intel") {
        $processorManufacturer = "Intel"
    }
    elseif ($cpuName -match "Apple") {
        $processorManufacturer = "Apple"
    }
    else {
        $processorManufacturer = "Unknown"
    }
    $numberOfCores = (& sysctl -n hw.physicalcpu).Trim()

    # L2 and L3 cache sizes (in bytes, so convert to MB)
    $l2CacheBytes = (& sysctl -n hw.l2cachesize).Trim()
    $l3CacheBytes = (& sysctl -n hw.l3cachesize 2>$null)
    $cpuL2MB = if ($l2CacheBytes) { [math]::Round([double]$l2CacheBytes / 1MB, 2) } else { "N/A" }
    $cpuL3MB = if ($l3CacheBytes) { [math]::Round([double]$l3CacheBytes / 1MB, 2) } else { "N/A" }

    # OS Name and Version
    $osName    = (& sw_vers -productName).Trim()
    $osVersion = (& sw_vers -productVersion).Trim()

    # Total Memory: hw.memsize returns bytes
    $memBytes   = (& sysctl -n hw.memsize).Trim()
    $totalMemGB = [math]::Round([double]$memBytes / 1GB, 2)

    # Available Memory: Using vm_stat to get free and inactive pages
    $vmStats = & vm_stat
    $pagesFree = ($vmStats | Where-Object { $_ -match "Pages free:" } |
                  ForEach-Object { ($_ -replace '[^0-9]', '') }) -as [int]
    $pagesInactive = ($vmStats | Where-Object { $_ -match "Pages inactive:" } |
                      ForEach-Object { ($_ -replace '[^0-9]', '') }) -as [int]
    $pageSize = [int](& sysctl -n hw.pagesize)
    $availMemGB = [math]::Round((($pagesFree + $pagesInactive) * $pageSize) / 1GB, 2)

    # Disk: Use df -k for the root filesystem; convert 1024-blocks to GB
    $dfOutput = & df -k /
    $dfLines = $dfOutput -split "`n"
    if ($dfLines.Length -ge 2) {
        $diskParts = $dfLines[1] -split "\s+"
        # df -k returns values in 1024-byte blocks; convert to GB
        $totalDiskGB = [math]::Round([double]$diskParts[1] / 1024 / 1024, 2)
        $availDiskGB = [math]::Round([double]$diskParts[3] / 1024 / 1024, 2)
    }
    else {
        $totalDiskGB = "N/A"
        $availDiskGB = "N/A"
    }
}
else {
    Write-Error "Unsupported OS."
    exit
}

# Create a custom object with the results and display it
$result = [PSCustomObject]@{
    "Processor Name"              = $cpuName
    "Processor Manufacturer"      = $processorManufacturer
    "Number of Processor Cores"   = $numberOfCores
    "CPU L2 Cache Size in MB"     = $cpuL2MB
    "CPU L3 Cache Size in MB"     = $cpuL3MB
    "OS Name"                     = $osName
    "OS Version"                  = $osVersion
    "Total Memory in GB"          = $totalMemGB
    "Available Memory in GB"      = $availMemGB
    "Total Disk Space in GB"      = $totalDiskGB
    "Available Disk Space in GB"  = $availDiskGB
}

$result #| Format-Table -AutoSize