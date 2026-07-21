<#
.SYNOPSIS
    Replaces matching text in a text file.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Pattern,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Replacement,

    [switch]$SimpleMatch
)

$content = Get-Content -LiteralPath $Path -Raw
$updated = if ($SimpleMatch) {
    $content.Replace($Pattern, $Replacement)
}
else {
    $content -replace $Pattern, $Replacement
}

if ($content -ceq $updated) {
    Write-Verbose 'No matching text was found.'
    return
}

if ($PSCmdlet.ShouldProcess($Path, "Replace text matching '$Pattern'")) {
    Set-Content -LiteralPath $Path -Value $updated -Encoding utf8 -NoNewline
}
