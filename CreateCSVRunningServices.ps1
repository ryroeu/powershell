<#
.SYNOPSIS
    Creates CSV running services.
#>

### Export Running Services to CSV ###
Get-Service | Where-Object {$_.status -eq "running"} `
            | Export-CSV C:\ExportDir\RunningServices.csv -NoTypeInformation