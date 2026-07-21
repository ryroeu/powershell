<#
.SYNOPSIS
    Removes Click-to-Run and Windows Installer (MSI) Office products with the Office Deployment Tool.
.DESCRIPTION
    Supply setup.exe from a current Office Deployment Tool package. RemoveMSI is included only when
    an MSI-based Office installation is detected.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$SetupPath,

    [string]$WorkDirectory = (Join-Path $env:TEMP 'ODT_RemoveAll'),

    [switch]$Silent,

    [switch]$ForceAppShutdown
)

$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$msiOffice = Get-ChildItem -Path $uninstallRoots -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty -LiteralPath $_.PSPath } |
    Where-Object { $_.DisplayName -match '^Microsoft (Office|365)' -and $_.WindowsInstaller -eq 1 }

$removeMsiElement = if ($msiOffice) { '  <RemoveMSI />' } else { '' }
$displayLevel = if ($Silent) { 'None' } else { 'Full' }
$forceShutdown = if ($ForceAppShutdown) { 'TRUE' } else { 'FALSE' }
$configuration = @"
<Configuration>
  <Remove All="TRUE" />
$removeMsiElement
  <Display Level="$displayLevel" AcceptEULA="TRUE" />
  <Property Name="FORCEAPPSHUTDOWN" Value="$forceShutdown" />
</Configuration>
"@

if (-not $PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Remove Click-to-Run and detected MSI Office products')) {
    return
}

New-Item -ItemType Directory -Path $WorkDirectory -Force | Out-Null
$configurationPath = Join-Path $WorkDirectory 'RemoveAllOffice.xml'
$configuration | Set-Content -LiteralPath $configurationPath -Encoding utf8NoBOM

$process = Start-Process -FilePath (Resolve-Path -LiteralPath $SetupPath).Path -ArgumentList '/configure', "`"$configurationPath`"" -Wait -PassThru
if ($process.ExitCode -notin 0, 3010) {
    throw "Office Deployment Tool failed with exit code $($process.ExitCode)."
}

[pscustomobject]@{
    ExitCode          = $process.ExitCode
    RestartNeeded     = $process.ExitCode -eq 3010
    MsiOfficeDetected = [bool]$msiOffice
    Configuration     = $configurationPath
}
