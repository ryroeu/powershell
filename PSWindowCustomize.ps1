<#
.SYNOPSIS
    Manages powershell window customize.
#>

if ($host.name -eq "ConsoleHost") { 
    $size=New-Object System.Management.Automation.Host.Size(120,60); $host.ui.rawui.WindowSize=$size 
}
$myHostWin = $host.ui.rawui 
$myHostWin.ForegroundColor = "Blue" 
$myHostWin.BackgroundColor = "Yellow" 
$myHostWin.WindowTitle = "Working Script"
