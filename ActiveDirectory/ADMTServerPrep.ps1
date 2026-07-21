<#
.SYNOPSIS
    Validates and optionally installs local prerequisites for an ADMT migration server.
.DESCRIPTION
    ADMT installers are not downloaded automatically because Microsoft download URLs and supported platforms change.
    Supply locally verified installer files and opt into each installation explicitly.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$SqlExpressInstaller,

    [string]$AdmtInstaller,

    [string]$PesInstallerPath,

    [switch]$InstallSqlExpress,

    [switch]$InstallAdmt,

    [switch]$InstallPasswordExportServer
)

$items = @(
    @{ Name = 'SQL Server Express'; Path = $SqlExpressInstaller; Install = $InstallSqlExpress; Arguments = @('/quiet') },
    @{ Name = 'Active Directory Migration Tool'; Path = $AdmtInstaller; Install = $InstallAdmt; Arguments = @('/quiet') },
    @{ Name = 'Password Export Server'; Path = $PesInstallerPath; Install = $InstallPasswordExportServer; Arguments = @('/qn', '/norestart') }
)

foreach ($item in $items) {
    $exists = $item.Path -and (Test-Path -LiteralPath $item.Path -PathType Leaf)
    [pscustomobject]@{ Prerequisite = $item.Name; InstallerPath = $item.Path; InstallerFound = [bool]$exists; InstallRequested = [bool]$item.Install }
    if (-not $item.Install) { continue }
    if (-not $exists) { throw "Installer for '$($item.Name)' was not found at '$($item.Path)'." }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Install $($item.Name)")) {
        $extension = [IO.Path]::GetExtension($item.Path)
        $process = if ($extension -eq '.msi') {
            Start-Process -FilePath msiexec.exe -ArgumentList (@('/i', "`"$($item.Path)`"") + $item.Arguments) -Wait -PassThru
        }
        else {
            Start-Process -FilePath $item.Path -ArgumentList $item.Arguments -Wait -PassThru
        }
        if ($process.ExitCode -notin 0, 3010) { throw "$($item.Name) installer failed with exit code $($process.ExitCode)." }
    }
}
