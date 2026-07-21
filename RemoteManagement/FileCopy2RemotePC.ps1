<#
.SYNOPSIS
    Copies a file or directory to the administrative share on remote Windows computers.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$ComputerListPath,

    [Parameter(Mandatory)]
    [string]$SourcePath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z]:\\')]
    [string]$DestinationPath,

    [switch]$Recurse,

    [switch]$Force
)

$computers = Get-Content -LiteralPath $ComputerListPath |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') }

foreach ($computer in $computers) {
    $drive = $DestinationPath.Substring(0, 1)
    $relativePath = $DestinationPath.Substring(3)
    $remotePath = "\\$computer\$drive`$\$relativePath"

    if ($PSCmdlet.ShouldProcess($remotePath, "Copy '$SourcePath'")) {
        Copy-Item -LiteralPath $SourcePath -Destination $remotePath -Recurse:$Recurse -Force:$Force -ErrorAction Stop
    }
}
