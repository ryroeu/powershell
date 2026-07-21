<#
.SYNOPSIS
    Replaces characters in filenames in a directory.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$Path = $PWD,

    [string]$Pattern = ' ',

    [string]$Replacement = '_',

    [switch]$Recurse
)

foreach ($file in Get-ChildItem -LiteralPath $Path -File -Recurse:$Recurse | Where-Object Name -Match $Pattern) {
    $newName = $file.Name -replace $Pattern, $Replacement
    if ($PSCmdlet.ShouldProcess($file.FullName, "Rename to '$newName'")) {
        Rename-Item -LiteralPath $file.FullName -NewName $newName
    }
}
