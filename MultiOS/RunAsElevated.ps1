<#
.SYNOPSIS
    Runs another PowerShell script with administrator or root privileges.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$FilePath,

    [string[]]$ArgumentList,

    [switch]$Wait
)

$resolvedPath = (Resolve-Path -LiteralPath $FilePath).Path
$isElevated = if ($IsWindows) {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}
else {
    (& id -u) -eq 0
}

if (-not $PSCmdlet.ShouldProcess($resolvedPath, 'Run PowerShell script with elevated privileges')) { return }
if ($isElevated) {
    & $resolvedPath @ArgumentList
    return
}

if ($IsWindows) {
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = (Join-Path $PSHOME 'pwsh.exe')
    $startInfo.Verb = 'runas'
    $startInfo.UseShellExecute = $true
    foreach ($argument in @('-NoProfile', '-File', $resolvedPath) + $ArgumentList) {
        [void]$startInfo.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::Start($startInfo)
}
elseif ($IsLinux -or $IsMacOS) {
    if (-not (Get-Command sudo -CommandType Application -ErrorAction SilentlyContinue)) { throw "'sudo' was not found." }
    $process = Start-Process -FilePath sudo -ArgumentList (@((Join-Path $PSHOME 'pwsh'), '-NoProfile', '-File', $resolvedPath) + $ArgumentList) -PassThru
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}

if ($Wait) {
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "Elevated script exited with code $($process.ExitCode)." }
}
else {
    $process
}
