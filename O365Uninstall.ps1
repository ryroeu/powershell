<# 
.SYNOPSIS
  Uninstall Microsoft 365 Apps (Click-to-Run) using ODT.

.EXAMPLE
  .\O365Uninstall.ps1 -Silent
#>
[CmdletBinding()]
param(
  [switch] $Silent,
  [string] $WorkDir = "$env:TEMP\ODT_Uninstall"
)
$ErrorActionPreference = 'Stop'
$newline = [Environment]::NewLine

# 1) Ensure ODT present (download if needed)
$odtZipUrl = "https://download.microsoft.com/download/2/6/5/26599e96-6b84-4def-96d7-79fb1a050a1d/officedeploymenttool_16130-20306.exe"
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
$setupExe = Join-Path $WorkDir "setup.exe"

if (-not (Test-Path $setupExe)) {
  Write-Host "Downloading Office Deployment Tool..." -ForegroundColor Yellow
  $exe = Join-Path $WorkDir "odt.exe"
  Invoke-WebRequest -Uri $odtZipUrl -OutFile $exe
  Start-Process -FilePath $exe -ArgumentList "/quiet /extract:$WorkDir" -Wait
}

# 2) Create minimal Remove-all config
$config = @"
<Configuration>
  <Remove All="TRUE" />
  <Display Level="$(if($Silent){'None'}else{'Full'})" AcceptEULA="TRUE" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Property Name="SharedComputerLicensing" Value="0" />
</Configuration>
"@
$configPath = Join-Path $WorkDir "RemoveO365.xml"
$config | Set-Content -Path $configPath -Encoding UTF8

# 3) Uninstall
Write-Host "Running ODT uninstall..." -ForegroundColor Cyan
$psi = Start-Process -FilePath $setupExe -ArgumentList "/configure `"$configPath`"" -Wait -PassThru
Write-Host "ODT exit code: $($psi.ExitCode)"
if ($psi.ExitCode -eq 0) { Write-Host "Uninstall complete." -ForegroundColor Green } else { Write-Warning "Uninstall finished with exit code $($psi.ExitCode)." }
Write-Host "Done." -ForegroundColor Green