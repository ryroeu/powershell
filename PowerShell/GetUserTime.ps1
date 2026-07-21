<#
.SYNOPSIS
    Returns a greeting based on the current local time.
#>

[CmdletBinding()]
param(
    [datetime]$DateTime = (Get-Date)
)

$greeting = if ($DateTime.Hour -lt 12) {
    'Good morning'
}
elseif ($DateTime.Hour -lt 18) {
    'Good afternoon'
}
else {
    'Good evening'
}

'{0}, the time is {1}' -f $greeting, $DateTime
