<#
.SYNOPSIS
    Retrieves user time.
#>

function Get-UserTime {
    # This function retrieves the current time and returns a greeting based on the time of day.
    $time = Get-Date -Hour (Get-Date).Hour -Minute (Get-Date).Minute -Second (Get-Date).Second
    # Get the current hour in 24-hour format
    $dateHour = Get-date -UFormat '%H'
    if ($dateHour -le 12) {
        "Good Morning, the time is $time"
    }
    ELSeIF ($dateHour -gt 12 -AND $dateHour -le 18) {
        "Good Afternoon, the time is $time"
    }
    ELSE {
        "Good Evening, the time is $time"
    }
}
Get-UserTime