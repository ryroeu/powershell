<#
.SYNOPSIS
    Manages services export running 2 html.
#>

### Export Running Service to HTML ###
Get-Service | Where-Object {$_.status -eq "running"} `
            | ConvertTo-HTML Name, DisplayName, Status `
            | Set-Content C:\ExportDir\RunningServices.html
