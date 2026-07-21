<#
.SYNOPSIS
    Adds a directory to PSModulePath without creating duplicate entries.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [ValidateSet('Process', 'User', 'Machine')]
    [string]$Target = 'User'
)

$expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
$currentValue = [Environment]::GetEnvironmentVariable('PSModulePath', $Target)
$entries = @($currentValue -split [regex]::Escape([IO.Path]::PathSeparator) | Where-Object { $_ })

if ($expandedPath -notin $entries) {
    $newValue = ($entries + $expandedPath) -join [IO.Path]::PathSeparator
    if ($PSCmdlet.ShouldProcess("PSModulePath ($Target)", "Add '$expandedPath'")) {
        [Environment]::SetEnvironmentVariable('PSModulePath', $newValue, $Target)
    }
}

[Environment]::GetEnvironmentVariable('PSModulePath', $Target)
