<#
.SYNOPSIS
    Adds CAB or MSU update packages to an offline WIM or VHD/VHDX image.
#>

#Requires -RunAsAdministrator

[CmdletBinding(DefaultParameterSetName = 'Wim', SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Wim')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$WimPath,

    [Parameter(Mandatory, ParameterSetName = 'Wim')]
    [ValidateRange(1, 1000)]
    [int]$WimIndex,

    [Parameter(Mandatory, ParameterSetName = 'Vhd')]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$VhdPath,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$PatchPath,

    [string]$MountPath = (Join-Path $env:TEMP 'PowerShellPatchMount'),

    [switch]$ResetBase
)

if (-not $IsWindows) { throw 'This script requires Windows.' }
$packages = @(Get-ChildItem -LiteralPath $PatchPath -Recurse -File |
        Where-Object Extension -In '.cab', '.msu' |
        Sort-Object FullName)
if (-not $packages) { throw "No CAB or MSU packages were found below '$PatchPath'." }

$target = if ($PSCmdlet.ParameterSetName -eq 'Wim') { "$WimPath (index $WimIndex)" } else { $VhdPath }
if (-not $PSCmdlet.ShouldProcess($target, "Install $($packages.Count) update package(s)")) {
    $packages
    return
}

if ($PSCmdlet.ParameterSetName -eq 'Wim') {
    if (-not (Get-Command Mount-WindowsImage -ErrorAction SilentlyContinue)) {
        throw 'The DISM PowerShell module is required.'
    }
    New-Item -ItemType Directory -Path $MountPath -Force | Out-Null
    if (Get-ChildItem -LiteralPath $MountPath -Force) { throw "Mount path '$MountPath' must be empty." }

    $saveImage = $false
    Mount-WindowsImage -ImagePath $WimPath -Index $WimIndex -Path $MountPath -ErrorAction Stop | Out-Null
    try {
        foreach ($package in $packages) {
            Add-WindowsPackage -Path $MountPath -PackagePath $package.FullName -ErrorAction Stop | Out-Null
        }
        if ($ResetBase) {
            & "$env:SystemRoot\System32\dism.exe" "/Image:$MountPath" /Cleanup-Image /StartComponentCleanup /ResetBase
            if ($LASTEXITCODE -ne 0) { throw "DISM cleanup failed with exit code $LASTEXITCODE." }
        }
        $saveImage = $true
    }
    finally {
        if ($saveImage) {
            Dismount-WindowsImage -Path $MountPath -Save -ErrorAction Stop | Out-Null
        }
        else {
            Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop | Out-Null
        }
    }
}
else {
    if (-not (Get-Command Mount-VHD -ErrorAction SilentlyContinue)) {
        throw 'The Hyper-V PowerShell module is required for VHD/VHDX images.'
    }

    $mountedVhd = Mount-VHD -Path $VhdPath -Passthru -ErrorAction Stop
    try {
        $disk = $mountedVhd | Get-Disk
        $volumes = Get-Partition -DiskNumber $disk.Number -ErrorAction Stop |
            Where-Object DriveLetter |
            Get-Volume
        $windowsVolume = $volumes | Where-Object {
            Test-Path -LiteralPath "$($_.DriveLetter):\Windows\System32"
        } | Select-Object -First 1
        if (-not $windowsVolume) { throw 'No offline Windows volume was found in the mounted VHD.' }
        $imagePath = "$($windowsVolume.DriveLetter):\"

        foreach ($package in $packages) {
            Add-WindowsPackage -Path $imagePath -PackagePath $package.FullName -ErrorAction Stop | Out-Null
        }
        if ($ResetBase) {
            & "$env:SystemRoot\System32\dism.exe" "/Image:$imagePath" /Cleanup-Image /StartComponentCleanup /ResetBase
            if ($LASTEXITCODE -ne 0) { throw "DISM cleanup failed with exit code $LASTEXITCODE." }
        }
    }
    finally {
        Dismount-VHD -Path $VhdPath -ErrorAction Stop
    }
}

[pscustomobject]@{ Target = $target; PackageCount = $packages.Count; ResetBase = $ResetBase.IsPresent; Completed = $true }
