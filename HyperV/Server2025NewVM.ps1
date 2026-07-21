<#
.SYNOPSIS
    Creates a generation 2 Hyper-V VM suitable for Windows Server 2022 or 2025.
#>

#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$VhdDirectory,

    [ValidateRange(20, 65536)]
    [int]$VhdSizeGB = 60,

    [ValidateRange(1, 1024)]
    [int]$MemoryStartupGB = 4,

    [ValidateRange(1, 2048)]
    [int]$ProcessorCount = 2,

    [string]$SwitchName,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$IsoPath,

    [switch]$EnableTpm,

    [switch]$AutomaticCheckpoints,

    [switch]$ReuseExistingVhd
)

if (-not $IsWindows) { throw 'This script requires Windows with the Hyper-V role.' }
if (Get-VM -Name $Name -ErrorAction SilentlyContinue) { throw "A VM named '$Name' already exists." }
if ($SwitchName -and -not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    throw "Virtual switch '$SwitchName' was not found."
}

$diskPath = Join-Path $VhdDirectory "$Name.vhdx"
if ((Test-Path -LiteralPath $diskPath) -and -not $ReuseExistingVhd) {
    throw "Virtual disk '$diskPath' already exists. Use -ReuseExistingVhd only when reuse is intentional."
}
if (-not $PSCmdlet.ShouldProcess($Name, 'Create Hyper-V virtual machine')) { return }

New-Item -ItemType Directory -Path $VhdDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $diskPath)) {
    New-VHD -Path $diskPath -SizeBytes ($VhdSizeGB * 1GB) -Dynamic -ErrorAction Stop | Out-Null
}

$newVmParameters = @{
    Name               = $Name
    Generation         = 2
    MemoryStartupBytes = $MemoryStartupGB * 1GB
    NoVHD              = $true
    ErrorAction        = 'Stop'
}
if ($SwitchName) { $newVmParameters.SwitchName = $SwitchName }
New-VM @newVmParameters | Out-Null

Set-VM -VMName $Name -ProcessorCount $ProcessorCount -DynamicMemory `
    -MemoryMinimumBytes 1GB -MemoryMaximumBytes ([Math]::Max($MemoryStartupGB * 1GB, 8GB)) `
    -AutomaticCheckpointsEnabled:$AutomaticCheckpoints -ErrorAction Stop
Add-VMHardDiskDrive -VMName $Name -Path $diskPath -ErrorAction Stop
Set-VMFirmware -VMName $Name -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows -ErrorAction Stop

if ($IsoPath) {
    $dvd = Add-VMDvdDrive -VMName $Name -Path (Resolve-Path -LiteralPath $IsoPath).Path -Passthru -ErrorAction Stop
    Set-VMFirmware -VMName $Name -FirstBootDevice $dvd -ErrorAction Stop
}
if ($EnableTpm) {
    Set-VMKeyProtector -VMName $Name -NewLocalKeyProtector -ErrorAction Stop
    Enable-VMTPM -VMName $Name -ErrorAction Stop
}

[pscustomobject]@{
    VM       = Get-VM -Name $Name
    DiskPath = $diskPath
    IsoPath  = $IsoPath
    Tpm      = $EnableTpm.IsPresent
}
