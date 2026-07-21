<#
.SYNOPSIS
    Removes ADMT agent remnants from a Windows computer.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$ServiceName = 'OnePointDomainAgent',

    [string]$ProcessName = 'admagnt',

    [string]$InstallPath = 'C:\Windows\ADMT',

    [string]$RegistryPath = 'HKLM:\Software\Microsoft\ADMT'
)

Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | ForEach-Object {
    if ($PSCmdlet.ShouldProcess($_.Id, "Stop process '$ProcessName'")) { $_ | Stop-Process -Force }
}

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($service -and $PSCmdlet.ShouldProcess($ServiceName, 'Stop and remove ADMT agent service')) {
    if ($service.Status -ne 'Stopped') { Stop-Service -Name $ServiceName -Force }
    & "$env:SystemRoot\System32\sc.exe" delete $ServiceName | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "sc.exe failed with exit code $LASTEXITCODE." }
}

foreach ($path in $RegistryPath, $InstallPath) {
    if ((Test-Path -LiteralPath $path) -and $PSCmdlet.ShouldProcess($path, 'Remove ADMT remnant')) {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}
