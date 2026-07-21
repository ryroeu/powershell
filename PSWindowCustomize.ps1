<#
.SYNOPSIS
    Customizes a console host window when the host supports RawUI.
#>

[CmdletBinding()]
param(
    [string]$Title = 'PowerShell',

    [ConsoleColor]$ForegroundColor = [ConsoleColor]::Gray,

    [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,

    [ValidateRange(20, 500)]
    [int]$Width = 120,

    [ValidateRange(10, 200)]
    [int]$Height = 40
)

try {
    $rawUi = $Host.UI.RawUI
    $maximum = $rawUi.MaxPhysicalWindowSize
    $size = [Management.Automation.Host.Size]::new(
        [Math]::Min($Width, $maximum.Width),
        [Math]::Min($Height, $maximum.Height)
    )
    $rawUi.WindowTitle = $Title
    $rawUi.ForegroundColor = $ForegroundColor
    $rawUi.BackgroundColor = $BackgroundColor
    $rawUi.WindowSize = $size
}
catch [Management.Automation.Host.HostException] {
    Write-Warning 'The current host does not support one or more RawUI window operations.'
}
