<#
.SYNOPSIS
    Retrieves Windows features.
#>

Get-WindowsFeature -Name PowerShell* | Format-Table | Export-Csv .\windowsfeaturestatus.csv -Append