<#
.SYNOPSIS
    Displays a text file.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string[]]$Path,

    [switch]$Raw
)

process {
    foreach ($item in $Path) {
        Get-Content -LiteralPath $item -Raw:$Raw
    }
}
