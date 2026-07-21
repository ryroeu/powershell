<#
.SYNOPSIS
    Demonstrates a small, reusable console menu.
#>

[CmdletBinding()]
param(
    [ValidateSet('1', '2', '3', '4', '5', 'Q')]
    [string]$Selection
)

$menuItems = [ordered]@{
    '1' = 'Function One'
    '2' = 'Function Two'
    '3' = 'Function Three'
    '4' = 'Function Four'
    '5' = 'Function Five'
}

if (-not $Selection) {
    Write-Host 'Console Menu' -ForegroundColor Cyan
    foreach ($entry in $menuItems.GetEnumerator()) {
        Write-Host "$($entry.Key): Execute $($entry.Value)"
    }
    Write-Host 'Q: Quit'
    $Selection = (Read-Host 'Select an option').ToUpperInvariant()
}

if ($Selection -eq 'Q') {
    [pscustomobject]@{ Selection = $Selection; Action = 'Quit'; Executed = $false }
}
elseif ($menuItems.Contains($Selection)) {
    [pscustomobject]@{ Selection = $Selection; Action = $menuItems[$Selection]; Executed = $true }
}
else {
    throw "Invalid menu selection '$Selection'."
}
