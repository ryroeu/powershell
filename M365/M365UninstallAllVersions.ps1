<# 
.SYNOPSIS
  Remove all Office installations (MSI and Click-to-Run) using ODT.

.EXAMPLE
  .\O365UninstallAllVersions.ps1 -Silent
#>
[CmdletBinding()]
param(
  [switch] $Silent,
  [string] $WorkDir = "$env:TEMP\ODT_RemoveAll"
)
$ErrorActionPreference = 'Stop'

# Ensure ODT setup.exe
$odtUrl = "https://download.microsoft.com/download/2/6/5/26599e96-6b84-4def-96d7-79fb1a050a1d/officedeploymenttool_16130-20306.exe"
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
$setupExe = Join-Path $WorkDir "setup.exe"
if (-not (Test-Path $setupExe)) {
  $exe = Join-Path $WorkDir "odt.exe"
  Invoke-WebRequest -Uri $odtUrl -OutFile $exe
  Start-Process -FilePath $exe -ArgumentList "/quiet /extract:$WorkDir" -Wait
}

# Detect MSI Office via registry (basic signal)
$msiOffice = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' `
  -ErrorAction SilentlyContinue | ForEach-Object { Get-ItemProperty $_.PsPath } |
  Where-Object { $_.DisplayName -match 'Microsoft Office' -and $_.WindowsInstaller }

# Build config that removes C2R and (if found) MSI
$removeMsiTag = if ($msiOffice) { '<RemoveMSI />' } else { '' }

$config = @"
<Configuration>
  <Remove All="TRUE" />
  $removeMsiTag
  <Display Level="$(if($Silent){'None'}else{'Full'})" AcceptEULA="TRUE" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
</Configuration>
"@

$configPath = Join-Path $WorkDir "RemoveAll.xml"
$config | Set-Content -Path $configPath -Encoding UTF8

Write-Host "Removing Office (C2R + MSI where present)..." -ForegroundColor Cyan
$code = (Start-Process -FilePath $setupExe -ArgumentList "/configure `"$configPath`"" -Wait -PassThru).ExitCode
Write-Host "ODT exit code: $code"
if ($code -eq 0) { Write-Host "Removal complete." -ForegroundColor Green } else { Write-Warning "Removal finished with exit code $code." }
Write-Host "Done." -ForegroundColor Green
Disconnect-MgGraph -Confirm:$false