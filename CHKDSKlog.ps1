<#
.SYNOPSIS
    Manages chkdsk log.
#>

Get-WinEvent -FilterHashTable @{logname="Application"; id="1001"} | Where-Object {$_.providername –Match "WinInit"} `
                                                                  | Format-List TimeCreated, Message `
                                                                  | Out-File CHKDSKResults.txt