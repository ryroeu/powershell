<#
.SYNOPSIS
    Creates or replaces a UTF-8 text file.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string[]]$Content,

    [switch]$Force
)

if ((Test-Path -LiteralPath $Path) -and -not $Force) {
    throw "The file '$Path' already exists. Use -Force to replace it."
}

if ($PSCmdlet.ShouldProcess($Path, 'Create text file')) {
    Set-Content -LiteralPath $Path -Value $Content -Encoding utf8 -Force:$Force
    Get-Item -LiteralPath $Path
}
