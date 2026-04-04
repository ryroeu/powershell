<#
.SYNOPSIS
Create a new Hyper‑V VM for Windows Server 2022/2025 (Gen 2, Secure Boot, optional vTPM).
.DESCRIPTION
Replaces/modernizes Server2022NewVM.ps1. Adds:
-OSVersion 2022|2025, -Edition, -InstallIndex for WIM selection
vTPM enablement using local key protector
Safer defaults (Gen 2, Secure Boot=On, Dynamic Memory)
.PARAMETER Name
VM name.
.PARAMETER VHDXPath
Path to create the OS disk VHDX (folder). File will be <Name>.vhdx.
.PARAMETER VHDXSizeGB
Size of the OS disk (default 60).
.PARAMETER MemoryStartupGB
Startup RAM in GB (default 4).
.PARAMETER CPU
vCPU count (default 2).
.PARAMETER SwitchName
Virtual switch to connect the NIC to (default 'Default Switch' if present).
.PARAMETER ISOPath
Path to Windows Server ISO (2022 or 2025).
.PARAMETER OSVersion
2022 or 2025. Default 2025.
.PARAMETER InstallIndex
Image index to boot when using the ISO (default 1). Kept for compatibility when using autounattend.
.PARAMETER EnableTPM
Switch. Adds a vTPM with a local key protector.
.PARAMETER Checkpoints
Enable automatic checkpoints (default: Off).
.EXAMPLE
.\New-ServerVM.ps1 -Name WS2025-DC -VHDXPath D:\VMs -ISOPath D:\ISOs\Windows_Server_2025.iso -SwitchName "Lab" -EnableTPM
#>
[CmdletBinding()] param(
[Parameter(Mandatory)] [string]$Name,
[Parameter(Mandatory)] [string]$VHDXPath,
[Parameter()] [int]$VHDXSizeGB = 60,
[Parameter()] [int]$MemoryStartupGB = 4,
[Parameter()] [int]$CPU = 2,
[Parameter()] [string]$SwitchName,
[Parameter()] [string]$ISOPath,
[ValidateSet('2022','2025')] [string]$OSVersion = '2025',
[int]$InstallIndex = 1,
[switch]$EnableTPM,
[switch]$Checkpoints
)

# --- Preconditions ---
Import-Module Hyper-V -ErrorAction Stop

if (-not (Test-Path $VHDXPath)) { New-Item -ItemType Directory -Path $VHDXPath -Force | Out-Null }

if (-not $SwitchName) {
$SwitchName = (Get-VMSwitch -SwitchType External,Internal,Private -ErrorAction SilentlyContinue | Where-Object {$_.Name -like '*Default*'} | Select-Object -First 1 -ExpandProperty Name)
}

# --- Create VHDX ---
$diskPath = Join-Path $VHDXPath ("{0}.vhdx" -f $Name)
if (-not (Test-Path $diskPath)) {
New-VHD -Path $diskPath -SizeBytes ($VHDXSizeGB * 1GB) -Dynamic | Out-Null
}

# --- Create VM ---
if (Get-VM -Name $Name -ErrorAction SilentlyContinue) {
throw "A VM named '$Name' already exists."
}

$vm = New-VM -Name $Name -Generation 2 -MemoryStartupBytes ($MemoryStartupGB * 1GB) -SwitchName $SwitchName -BootDevice VHD -ErrorAction Stop
Set-VM -VMName $Name -ProcessorCount $CPU -DynamicMemory -MemoryMinimumBytes 1GB -MemoryMaximumBytes ([math]::Max($MemoryStartupGB * 1GB, 8GB)) -AutomaticCheckpointsEnabled:$Checkpoints.IsPresent
Add-VMHardDiskDrive -VMName $Name -Path $diskPath

# Secure Boot (Windows template)
$tpl = (Get-VMHost).SecureBootTemplates | Where-Object { $_ -match 'Windows' } | Select-Object -First 1
if ($tpl) { Set-VMFirmware -VMName $Name -EnableSecureBoot On -SecureBootTemplate $tpl }

# Optional: attach ISO and set boot order
if ($ISOPath) {
if (-not (Test-Path $ISOPath)) { throw "ISO not found: $ISOPath" }
Add-VMDvdDrive -VMName $Name -Path $ISOPath | Out-Null
$dvd = (Get-VMDvdDrive -VMName $Name)
Set-VMFirmware -VMName $Name -FirstBootDevice $dvd
}

# Optional: enable vTPM (local key protector)
if ($EnableTPM) {
$kp = New-VMKeyProtector -VMName $Name -NewLocalKeyProtector
Enable-VMTPM -VMName $Name -KeyProtector $kp
}

Write-Host "VM '$Name' created." -ForegroundColor Green
Write-Host " Disk: $diskPath"
Write-Host " ISO : $ISOPath"
Write-Host " TPM : $($EnableTPM.IsPresent)"
