<#
.SYNOPSIS
    Retrieves child item last write.
#>

Param(
    [Parameter(Mandatory=$true)]
    [Datetime]$LastWrite
)
Get-ChildItem -Path $path | Where-Object -FilterScript {($_.LastWriteTime -gt $LastWrite)}