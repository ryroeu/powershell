<#
.SYNOPSIS
    Collects a structured Windows computer inventory.
#>

[CmdletBinding()]
param(
    [ValidateRange(1, 100)]
    [int]$TopProcessCount = 10,

    [switch]$IncludeLicensing
)

if (-not $IsWindows) {
    throw 'This script requires Windows.'
}

$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
$processors = @(Get-CimInstance -ClassName Win32_Processor)

$result = [ordered]@{
    ComputerName     = $computerSystem.Name
    LoggedOnUser     = $computerSystem.UserName
    Manufacturer     = $computerSystem.Manufacturer
    Model            = $computerSystem.Model
    OperatingSystem  = $operatingSystem.Caption
    OSVersion        = $operatingSystem.Version
    OSBuild          = $operatingSystem.BuildNumber
    LastBootTime     = $operatingSystem.LastBootUpTime
    BiosManufacturer = $bios.Manufacturer
    BiosVersion      = $bios.SMBIOSBIOSVersion
    BiosSerialNumber = $bios.SerialNumber
    Processor        = $processors | Select-Object Name, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors
    Disk             = @(Get-Disk | Select-Object Number, FriendlyName, PartitionStyle, OperationalStatus, HealthStatus, Size)
    Volume           = @(Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus, Size, SizeRemaining)
    NetworkAdapter   = @(Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress)
    NetworkProfile   = @(Get-NetConnectionProfile | Select-Object Name, InterfaceAlias, IPv4Connectivity, IPv6Connectivity, NetworkCategory)
    IPAddress        = @(Get-NetIPAddress | Select-Object InterfaceAlias, AddressFamily, IPAddress, PrefixLength)
    DnsServer        = @(Get-DnsClientServerAddress | Select-Object InterfaceAlias, AddressFamily, ServerAddresses)
    TopProcessByCpu  = @(Get-Process | Sort-Object CPU -Descending | Select-Object -First $TopProcessCount Name, Id, CPU, WorkingSet64)
}

if ($IncludeLicensing) {
    $result.Licensing = @(Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL" |
            Select-Object Name, Description, LicenseStatus, PartialProductKey)
}

[pscustomobject]$result
