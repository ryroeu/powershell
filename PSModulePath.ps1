<#
.SYNOPSIS
    Manages powershell module path.
#>

$CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
[Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + [System.IO.Path]::PathSeparator + "/Program Files/Powershell/Modules", "Machine")
$env:PSModulePath