<#
.SYNOPSIS
    Renames files in a directory to a sequential pattern.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$Directory,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Prefix,

    [ValidateRange(0, [int]::MaxValue)]
    [int]$StartNumber = 1,

    [ValidateRange(1, 12)]
    [int]$Padding = 4,

    [string]$Filter = '*'
)

$files = @(Get-ChildItem -LiteralPath $Directory -Filter $Filter -File | Sort-Object Name)
$renames = for ($index = 0; $index -lt $files.Count; $index++) {
    $newName = '{0}_{1}{2}' -f $Prefix, ($StartNumber + $index).ToString("D$Padding"), $files[$index].Extension
    [pscustomobject]@{ Source = $files[$index]; NewName = $newName; Target = Join-Path $Directory $newName }
}

foreach ($rename in $renames) {
    if ((Test-Path -LiteralPath $rename.Target) -and $rename.Source.FullName -ne (Resolve-Path -LiteralPath $rename.Target).Path) {
        throw "Target file already exists: '$($rename.Target)'."
    }
}

foreach ($rename in $renames | Where-Object { $_.Source.Name -ne $_.NewName }) {
    if ($PSCmdlet.ShouldProcess($rename.Source.FullName, "Rename to '$($rename.NewName)'")) {
        Rename-Item -LiteralPath $rename.Source.FullName -NewName $rename.NewName -ErrorAction Stop
    }
}

$renames | Select-Object @{ Name = 'OldName'; Expression = { $_.Source.Name } }, NewName, Target
