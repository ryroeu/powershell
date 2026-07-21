<#
.SYNOPSIS
    Reports CPU, operating system, memory, and disk capacity across supported platforms.
#>

#Requires -Version 7.0

[CmdletBinding()]
param()

function ConvertTo-Megabyte {
    param([string]$Text)
    if ($Text -notmatch '(?<Value>[\d.]+)\s*(?<Unit>KiB|MiB|GiB|KB|MB|GB|K|M|G)?') { return $null }
    $value = [double]$Matches.Value
    switch -Regex ($Matches.Unit) {
        '^(KiB|KB|K)$' { return [Math]::Round($value / 1024, 2) }
        '^(GiB|GB|G)$' { return [Math]::Round($value * 1024, 2) }
        default { return [Math]::Round($value, 2) }
    }
}

$processorName = $null
$processorManufacturer = $null
$physicalCoreCount = $null
$l2CacheMB = $null
$l3CacheMB = $null
$totalMemoryGB = $null
$availableMemoryGB = $null

if ($IsWindows) {
    $processors = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $processorName = ($processors.Name | Sort-Object -Unique) -join '; '
    $processorManufacturer = ($processors.Manufacturer | Sort-Object -Unique) -join '; '
    $physicalCoreCount = ($processors | Measure-Object NumberOfCores -Sum).Sum
    $l2CacheMB = [Math]::Round((($processors | Measure-Object L2CacheSize -Sum).Sum) / 1KB, 2)
    $l3CacheMB = [Math]::Round((($processors | Measure-Object L3CacheSize -Sum).Sum) / 1KB, 2)
    $totalMemoryGB = [Math]::Round($operatingSystem.TotalVisibleMemorySize / 1MB, 2)
    $availableMemoryGB = [Math]::Round($operatingSystem.FreePhysicalMemory / 1MB, 2)
}
elseif ($IsLinux) {
    $cpuInfo = Get-Content -LiteralPath /proc/cpuinfo -ErrorAction Stop
    $processorName = (($cpuInfo | Where-Object { $_ -match '^model name\s*:' } | Select-Object -First 1) -split ':', 2)[1].Trim()
    $processorManufacturer = (($cpuInfo | Where-Object { $_ -match '^vendor_id\s*:' } | Select-Object -First 1) -split ':', 2)[1].Trim()

    $lscpu = @(& lscpu 2>$null)
    if ($LASTEXITCODE -eq 0) {
        $values = @{}
        foreach ($line in $lscpu) {
            if ($line -match '^(?<Name>[^:]+):\s*(?<Value>.*)$') { $values[$Matches.Name.Trim()] = $Matches.Value.Trim() }
        }
        if ($values['Socket(s)'] -and $values['Core(s) per socket']) {
            $physicalCoreCount = [int]$values['Socket(s)'] * [int]$values['Core(s) per socket']
        }
        $l2CacheMB = ConvertTo-Megabyte $values['L2 cache']
        $l3CacheMB = ConvertTo-Megabyte $values['L3 cache']
    }
    if (-not $physicalCoreCount) { $physicalCoreCount = [Environment]::ProcessorCount }

    $memoryInfo = @{}
    foreach ($line in Get-Content -LiteralPath /proc/meminfo) {
        if ($line -match '^(?<Name>\w+):\s*(?<Value>\d+)\s+kB') { $memoryInfo[$Matches.Name] = [double]$Matches.Value }
    }
    $totalMemoryGB = [Math]::Round($memoryInfo.MemTotal / 1MB, 2)
    $availableMemoryGB = [Math]::Round($memoryInfo.MemAvailable / 1MB, 2)
}
elseif ($IsMacOS) {
    $processorName = (& /usr/sbin/sysctl -n machdep.cpu.brand_string 2>$null).Trim()
    if (-not $processorName) { $processorName = (& /usr/sbin/sysctl -n hw.model).Trim() }
    $processorManufacturer = if ($processorName -match 'Apple') { 'Apple' } elseif ($processorName -match 'Intel') { 'Intel' } else { $null }
    $physicalCoreCount = [int](& /usr/sbin/sysctl -n hw.physicalcpu)
    $l2CacheMB = [Math]::Round([double](& /usr/sbin/sysctl -n hw.l2cachesize) / 1MB, 2)
    $l3Bytes = & /usr/sbin/sysctl -n hw.l3cachesize 2>$null
    if ($l3Bytes) { $l3CacheMB = [Math]::Round([double]$l3Bytes / 1MB, 2) }
    $totalMemoryGB = [Math]::Round([double](& /usr/sbin/sysctl -n hw.memsize) / 1GB, 2)

    $vmStatistics = @(& /usr/bin/vm_stat)
    $pageSize = if ($vmStatistics[0] -match 'page size of (?<Size>\d+) bytes') { [double]$Matches.Size } else { 4096 }
    $availablePages = 0
    foreach ($name in 'Pages free', 'Pages inactive', 'Pages speculative') {
        $line = $vmStatistics | Where-Object { $_ -like "$name:*" } | Select-Object -First 1
        if ($line -match ':\s*(?<Pages>\d+)') { $availablePages += [double]$Matches.Pages }
    }
    $availableMemoryGB = [Math]::Round(($availablePages * $pageSize) / 1GB, 2)
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}

$drives = @([IO.DriveInfo]::GetDrives() | Where-Object IsReady)
$totalDiskBytes = ($drives | Measure-Object TotalSize -Sum).Sum
$availableDiskBytes = ($drives | Measure-Object AvailableFreeSpace -Sum).Sum

[pscustomobject]@{
    ComputerName          = [Environment]::MachineName
    Platform              = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } else { 'macOS' }
    OperatingSystem       = [Runtime.InteropServices.RuntimeInformation]::OSDescription
    OSArchitecture        = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    ProcessorName         = $processorName
    ProcessorManufacturer = $processorManufacturer
    PhysicalCoreCount     = $physicalCoreCount
    LogicalProcessorCount = [Environment]::ProcessorCount
    L2CacheMB             = $l2CacheMB
    L3CacheMB             = $l3CacheMB
    TotalMemoryGB         = $totalMemoryGB
    AvailableMemoryGB     = $availableMemoryGB
    TotalDiskGB           = [Math]::Round($totalDiskBytes / 1GB, 2)
    AvailableDiskGB       = [Math]::Round($availableDiskBytes / 1GB, 2)
}
