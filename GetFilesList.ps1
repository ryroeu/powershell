<#
.SYNOPSIS
    Retrieves files list.
#>

Get-ChildItem -Path C:\Windows\System32 -Recurse -File | `
    Select-Object -Property Name | Sort-Object -Property Name | `
    Export-Csv -Path C:\Temp\System32Files.csv -UseCulture
