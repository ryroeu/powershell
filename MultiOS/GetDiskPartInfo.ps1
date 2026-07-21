#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Retrieves disk and partition information across Windows, Linux, and macOS.

.DESCRIPTION
    This script provides a cross-platform version of GetDiskPartInfo.ps1.
    It keeps the original DiskNum/Model/Type/DiskSize shape and adds:
      - Platform: Windows, Linux, or macOS
      - Device: native device path when available
      - AccessPath: drive letters on Windows, mount points on Linux/macOS

    For compatibility with the original script, the DriveLetter property is still
    returned. On Linux and macOS it contains mount points instead of drive letters.

.NOTES
    PowerShell 7+ is recommended for Linux and macOS.
#>

function Get-PropertyValue {
    param(
        [Parameter(Mandatory)]
        [object]$Object,

        [Parameter(Mandatory)]
        [string[]]$Name
    )

    foreach ($propertyName in $Name) {
        $property = $Object.PSObject.Properties[$propertyName]
        if ($property -and $null -ne $property.Value -and "$($property.Value)" -ne '') {
            return $property.Value
        }
    }

    return $null
}

function Join-AccessPath {
    param(
        [AllowNull()]
        [object[]]$Path,

        [string]$EmptyValue = '[No Access Path]'
    )

    $items = foreach ($entry in @($Path)) {
        if ($entry -is [System.Array]) {
            foreach ($nestedEntry in $entry) {
                if ($null -ne $nestedEntry) {
                    $text = "$nestedEntry".Trim()
                    if ($text) {
                        $text
                    }
                }
            }
        }
        elseif ($null -ne $entry) {
            $text = "$entry".Trim()
            if ($text) {
                $text
            }
        }
    }

    $clean = @($items | Sort-Object -Unique)
    if ($clean.Count -gt 0) {
        return $clean -join ','
    }

    return $EmptyValue
}

function ConvertFrom-PlistNode {
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlNode]$Node
    )

    switch ($Node.Name) {
        'dict' {
            $result = [ordered]@{}
            $children = @(
                $Node.ChildNodes |
                    Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element }
            )

            for ($index = 0; $index -lt $children.Count; $index += 2) {
                if ($children[$index].Name -ne 'key' -or ($index + 1) -ge $children.Count) {
                    continue
                }

                $keyName = $children[$index].InnerText
                $result[$keyName] = ConvertFrom-PlistNode -Node $children[$index + 1]
            }

            return [PSCustomObject]$result
        }
        'array' {
            return @(
                $Node.ChildNodes |
                    Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element } |
                    ForEach-Object { ConvertFrom-PlistNode -Node $_ }
            )
        }
        'integer' { return [int64]$Node.InnerText }
        'real' { return [double]$Node.InnerText }
        'true' { return $true }
        'false' { return $false }
        default { return $Node.InnerText }
    }
}

function ConvertFrom-PlistText {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    if (-not $Text.Trim()) {
        return $null
    }

    [xml]$plistXml = $Text
    return ConvertFrom-PlistNode -Node $plistXml.plist.dict
}

function Resolve-LinuxDiskType {
    param(
        [Parameter(Mandatory)]
        [psobject]$Disk
    )

    $transport = "$($Disk.tran)".Trim().ToLowerInvariant()
    $path = "$($Disk.path)".Trim().ToLowerInvariant()
    $rotational = "$($Disk.rota)".Trim().ToLowerInvariant()
    $removable = "$($Disk.rm)".Trim().ToLowerInvariant()

    if ($transport -eq 'nvme' -or $path -like '/dev/nvme*') {
        return 'NVMe'
    }

    if ($removable -in @('1', 'true') -and $transport -eq 'usb') {
        return 'Removable'
    }

    if ($rotational -in @('0', 'false')) {
        return 'SSD'
    }

    if ($rotational -in @('1', 'true')) {
        return 'HDD'
    }

    return 'Unknown'
}

function Get-LinuxMountPoint {
    param(
        [Parameter(Mandatory)]
        [psobject]$Node
    )

    $mountPoints = @()

    if ($Node.PSObject.Properties['mountpoint'] -and $Node.mountpoint) {
        $mountPoints += $Node.mountpoint
    }

    if ($Node.PSObject.Properties['children']) {
        foreach ($child in @($Node.children)) {
            $mountPoints += Get-LinuxMountPoint -Node $child
        }
    }

    return @($mountPoints | Where-Object { $_ } | Sort-Object -Unique)
}

function Resolve-MacDiskType {
    param(
        [AllowNull()]
        [psobject]$DiskInfo,

        [string[]]$MountPoint = @()
    )

    $mountText = ($MountPoint -join ' ')
    if ($mountText -match 'CoreSimulator|AppTranslocation|cryptexd') {
        return 'Virtual'
    }

    if ($DiskInfo) {
        $model = Get-PropertyValue -Object $DiskInfo -Name @('MediaName', 'DeviceModel')
        $busProtocol = Get-PropertyValue -Object $DiskInfo -Name @('BusProtocol', 'Protocol')
        $solidState = Get-PropertyValue -Object $DiskInfo -Name @('SolidState')

        $signal = @("$model", "$busProtocol") -join ' '
        if ($signal -match 'NVMe|PCI-Express|Apple SSD') {
            return 'NVMe'
        }

        if ($solidState -eq $true -or $signal -match 'SSD|Flash') {
            return 'SSD'
        }

        if ($solidState -eq $false) {
            return 'HDD'
        }
    }

    return 'Unknown'
}

function Get-WindowsDiskInfo {
    Write-Verbose 'Gathering disk information using Windows Storage cmdlets.'

    $physicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    if (-not $physicalDisks) {
        Write-Warning 'Could not retrieve physical disk information. Ensure the Storage module is available and functional.'
        return
    }

    foreach ($physicalDisk in $physicalDisks) {
        $accessPath = $null

        try {
            $disk = Get-Disk -Number $physicalDisk.DeviceID -ErrorAction Stop
            $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue

            if ($partitions) {
                $letters = $partitions |
                    Where-Object { $_.DriveLetter } |
                    Select-Object -ExpandProperty DriveLetter

                if ($letters) {
                    $accessPath = ($letters | ForEach-Object { '{0}:' -f $_ }) -join ','
                }
                else {
                    $accessPath = '[No Letter]'
                }
            }
            else {
                $accessPath = '[No Partitions]'
            }
        }
        catch {
            Write-Warning "Error processing Windows disk $($physicalDisk.DeviceID): $($_.Exception.Message)"
            $accessPath = '[Error]'
        }

        $type = "$($physicalDisk.MediaType)"
        if (($type -eq 'Unspecified' -or -not $type) -and "$($physicalDisk.BusType)" -eq 'NVMe') {
            $type = 'NVMe'
        }

        [PSCustomObject]@{
            Platform    = 'Windows'
            DiskNum     = "$($physicalDisk.DeviceID)"
            Device      = "\\.\PHYSICALDRIVE$($physicalDisk.DeviceID)"
            Model       = if ($physicalDisk.Model) { $physicalDisk.Model.Trim() } else { '[Unknown]' }
            Type        = $type
            DiskSize    = [uint64]$physicalDisk.Size
            DriveLetter = $accessPath
            AccessPath  = $accessPath
        }
    }
}

function Get-LinuxDiskInfo {
    Write-Verbose 'Gathering disk information using lsblk.'

    $lsblk = Get-Command lsblk -ErrorAction SilentlyContinue
    if (-not $lsblk) {
        Write-Warning 'The lsblk command is required on Linux but was not found.'
        return
    }

    try {
        $jsonText = & $lsblk.Source -J -b -o NAME, PATH, MODEL, TYPE, SIZE, MOUNTPOINT, ROTA, RM, TRAN, SERIAL 2>$null | Out-String
        if (-not $jsonText.Trim()) {
            Write-Warning 'lsblk did not return any data.'
            return
        }

        $diskData = $jsonText | ConvertFrom-Json
    }
    catch {
        Write-Warning "Unable to parse lsblk output: $($_.Exception.Message)"
        return
    }

    foreach ($disk in @($diskData.blockdevices)) {
        if ($disk.type -ne 'disk') {
            continue
        }

        $mountPoints = Get-LinuxMountPoint -Node $disk
        $accessPath = Join-AccessPath -Path $mountPoints -EmptyValue '[No Mounts]'
        $model = if ($disk.model) { "$($disk.model)".Trim() } elseif ($disk.serial) { "$($disk.serial)".Trim() } else { '[Unknown]' }

        [PSCustomObject]@{
            Platform    = 'Linux'
            DiskNum     = "$($disk.name)"
            Device      = if ($disk.path) { "$($disk.path)".Trim() } else { "/dev/$($disk.name)" }
            Model       = $model
            Type        = Resolve-LinuxDiskType -Disk $disk
            DiskSize    = [uint64]$disk.size
            DriveLetter = $accessPath
            AccessPath  = $accessPath
        }
    }
}

function Get-MacDiskutilInfo {
    param(
        [Parameter(Mandatory)]
        [string]$DiskIdentifier
    )

    $diskutil = Get-Command diskutil -ErrorAction SilentlyContinue
    if (-not $diskutil) {
        return $null
    }

    try {
        $plistText = & $diskutil.Source info -plist "/dev/$DiskIdentifier" 2>$null | Out-String
        if (-not $plistText.Trim()) {
            return $null
        }

        return ConvertFrom-PlistText -Text $plistText
    }
    catch {
        return $null
    }
}

function Get-MacDiskInfo {
    Write-Verbose 'Gathering disk information using diskutil and df.'

    $mountRows = foreach ($line in (& df -kP 2>$null | Select-Object -Skip 1)) {
        $parts = $line.Trim() -split '\s+', 6
        if ($parts.Count -lt 6) {
            continue
        }

        $filesystem = $parts[0]
        if ($filesystem -notmatch '^/dev/disk') {
            continue
        }

        $deviceName = [System.IO.Path]::GetFileName($filesystem)
        $baseDisk = ([regex]::Match($deviceName, '^disk\d+')).Value
        if (-not $baseDisk) {
            $baseDisk = $deviceName
        }

        [PSCustomObject]@{
            DeviceName = $deviceName
            BaseDisk   = $baseDisk
            MountPoint = $parts[5]
            SizeBytes  = [uint64]$parts[1] * 1KB
        }
    }

    if (-not $mountRows) {
        Write-Warning 'No mounted macOS disks were discovered.'
        return
    }

    $wholeDiskMap = @{}
    foreach ($baseDisk in ($mountRows.BaseDisk | Sort-Object -Unique)) {
        $diskInfo = Get-MacDiskutilInfo -DiskIdentifier $baseDisk
        $wholeDiskId = if ($diskInfo) {
            Get-PropertyValue -Object $diskInfo -Name @('ParentWholeDisk', 'DeviceIdentifier')
        }
        else {
            $null
        }

        if (-not $wholeDiskId) {
            $wholeDiskId = $baseDisk
        }

        if (-not $wholeDiskMap.ContainsKey($wholeDiskId)) {
            $wholeDiskMap[$wholeDiskId] = [System.Collections.Generic.List[object]]::new()
        }

        foreach ($row in @($mountRows | Where-Object { $_.BaseDisk -eq $baseDisk })) {
            $wholeDiskMap[$wholeDiskId].Add($row)
        }
    }

    foreach ($wholeDiskId in ($wholeDiskMap.Keys | Sort-Object)) {
        $rows = @($wholeDiskMap[$wholeDiskId])
        $mountPoints = @($rows.MountPoint | Sort-Object -Unique)
        $diskInfo = Get-MacDiskutilInfo -DiskIdentifier $wholeDiskId

        $model = if ($diskInfo) {
            Get-PropertyValue -Object $diskInfo -Name @('MediaName', 'DeviceModel', 'IORegistryEntryName')
        }
        else {
            '[Unknown]'
        }

        $size = if ($diskInfo) {
            Get-PropertyValue -Object $diskInfo -Name @('TotalSize', 'DiskSize', 'Size')
        }
        else {
            ($rows | Measure-Object -Property SizeBytes -Maximum).Maximum
        }

        $device = if ($diskInfo) {
            Get-PropertyValue -Object $diskInfo -Name @('DeviceNode')
        }
        else {
            "/dev/$wholeDiskId"
        }

        $accessPath = Join-AccessPath -Path $mountPoints -EmptyValue '[No Mounts]'

        [PSCustomObject]@{
            Platform    = 'macOS'
            DiskNum     = $wholeDiskId
            Device      = if ($device) { $device } else { "/dev/$wholeDiskId" }
            Model       = if ($model) { "$model".Trim() } else { '[Unknown]' }
            Type        = Resolve-MacDiskType -DiskInfo $diskInfo -MountPoint $mountPoints
            DiskSize    = [uint64]$size
            DriveLetter = $accessPath
            AccessPath  = $accessPath
        }
    }
}

function Get-DiskInfoAdvanced {
    [CmdletBinding()]
    param()

    if ($IsWindows) {
        return Get-WindowsDiskInfo
    }

    if ($IsLinux) {
        return Get-LinuxDiskInfo
    }

    if ($IsMacOS) {
        return Get-MacDiskInfo
    }

    Write-Error 'Unsupported operating system.'
}

# Example usage:
# Get-DiskInfoAdvanced -Verbose

$diskData = Get-DiskInfoAdvanced
$diskData |
    Select-Object Platform, DiskNum, Device, Model, Type,
    @{ Name = 'DiskSizeGB'; Expression = { [math]::Round([double]$_.DiskSize / 1GB, 2) } },
    AccessPath
