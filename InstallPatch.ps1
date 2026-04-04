function Invoke-DismCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ArgumentList
    )

    & dism.exe @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw ('dism.exe failed with exit code {0}. Arguments: {1}' -f $LASTEXITCODE, ($ArgumentList -join ' '))
    }
}

function Install-Patch {
    <#
    .SYNOPSIS
        Patches a WIM or VHD file.
    .DESCRIPTION
        Applies downloaded .msu or .cab updates to a VHD/VHDX or WIM image.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UpdateTargetPassed,

        [Parameter(Mandatory)]
        [string]$PatchPath
    )

    $isVhd = $UpdateTargetPassed.ToLowerInvariant().Contains('.vhd')
    $updateTarget = $null
    $updateTargetIndex = $null
    $mountPath = $null

    if ($isVhd) {
        $updateTarget = $UpdateTargetPassed
        if (-not (Test-Path -LiteralPath $updateTarget)) {
            throw ('Source not found: {0}' -f $updateTarget)
        }

        Mount-VHD -Path $updateTarget -ErrorAction Stop
        try {
            $disk = Get-CimInstance -ClassName Win32_DiskDrive |
                Where-Object Caption -eq 'Microsoft Virtual Disk' |
                Select-Object -First 1

            if (-not $disk) {
                throw 'Unable to locate the mounted virtual disk.'
            }

            $updatedDrive = Get-CimAssociatedInstance -CimInstance $disk -ResultClassName Win32_DiskPartition |
                ForEach-Object {
                    Get-CimAssociatedInstance -CimInstance $_ -ResultClassName Win32_LogicalDisk
                } |
                Where-Object VolumeName -ne 'System Reserved' |
                Select-Object -First 1

            if (-not $updatedDrive) {
                throw 'Unable to locate a usable logical disk on the mounted VHD.'
            }

            $mountPath = '{0}\' -f $updatedDrive.DeviceID
            $updates = Get-ChildItem -Path $PatchPath -Recurse -File |
                Where-Object { $_.Extension -in '.msu', '.cab' }

            foreach ($update in $updates) {
                Write-Verbose ('Applying {0}' -f $update.FullName)
                Invoke-DismCommand -ArgumentList @(
                    ('/Image:{0}' -f $mountPath),
                    '/Add-Package',
                    ('/PackagePath:{0}' -f $update.FullName)
                )
            }

            Invoke-DismCommand -ArgumentList @(
                ('/Image:{0}' -f $mountPath),
                '/Cleanup-Image',
                '/SPSuperseded'
            )
        }
        finally {
            Dismount-VHD -Path $updateTarget -Confirm:$false
        }

        return
    }

    $targetParts = $UpdateTargetPassed.Split(':')
    if ($targetParts.Count -ne 3) {
        throw 'Missing index number for WIM file. Example: C:\Temp\install.wim:4'
    }

    $updateTarget = '{0}:{1}' -f $targetParts[0], $targetParts[1]
    $updateTargetIndex = $targetParts[2]
    $mountPath = 'C:\WimMount'

    if (-not (Test-Path -LiteralPath $mountPath)) {
        New-Item -Path $mountPath -ItemType Directory -Force | Out-Null
    }

    Invoke-DismCommand -ArgumentList @(
        '/Mount-Wim',
        ('/WimFile:{0}' -f $updateTarget),
        ('/Index:{0}' -f $updateTargetIndex),
        ('/MountDir:{0}' -f $mountPath)
    )

    try {
        $updates = Get-ChildItem -Path $PatchPath -Recurse -File |
            Where-Object { $_.Extension -in '.msu', '.cab' }

        foreach ($update in $updates) {
            Write-Verbose ('Applying {0}' -f $update.FullName)
            Invoke-DismCommand -ArgumentList @(
                ('/Image:{0}' -f $mountPath),
                '/Add-Package',
                ('/PackagePath:{0}' -f $update.FullName)
            )
        }

        Invoke-DismCommand -ArgumentList @(
            ('/Image:{0}' -f $mountPath),
            '/Cleanup-Image',
            '/SPSuperseded'
        )
    }
    finally {
        Invoke-DismCommand -ArgumentList @(
            '/Unmount-Wim',
            ('/MountDir:{0}' -f $mountPath),
            '/Commit'
        )
    }
}
