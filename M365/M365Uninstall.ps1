<#
.SYNOPSIS
    Removes Microsoft 365 Apps Click-to-Run products with the Office Deployment Tool.
.DESCRIPTION
    Supply setup.exe from a current Office Deployment Tool package. The script intentionally does
    not pin a version-specific download URL.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$SetupPath,

    [string]$WorkDirectory = (Join-Path $env:TEMP 'ODT_Uninstall'),

    [switch]$Silent,

    [switch]$ForceAppShutdown
)

$displayLevel = if ($Silent) { 'None' } else { 'Full' }
$forceShutdown = if ($ForceAppShutdown) { 'TRUE' } else { 'FALSE' }
$configuration = @"
<Configuration>
  <Remove All="TRUE" />
  <Display Level="$displayLevel" AcceptEULA="TRUE" />
  <Property Name="FORCEAPPSHUTDOWN" Value="$forceShutdown" />
</Configuration>
"@

if (-not $PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Remove all Microsoft 365 Apps Click-to-Run products')) {
    return
}

New-Item -ItemType Directory -Path $WorkDirectory -Force | Out-Null
$configurationPath = Join-Path $WorkDirectory 'RemoveMicrosoft365.xml'
$configuration | Set-Content -LiteralPath $configurationPath -Encoding utf8NoBOM

$process = Start-Process -FilePath (Resolve-Path -LiteralPath $SetupPath).Path -ArgumentList '/configure', "`"$configurationPath`"" -Wait -PassThru
if ($process.ExitCode -notin 0, 3010) {
    throw "Office Deployment Tool failed with exit code $($process.ExitCode)."
}

[pscustomobject]@{
    ExitCode      = $process.ExitCode
    RestartNeeded = $process.ExitCode -eq 3010
    Configuration = $configurationPath
}
