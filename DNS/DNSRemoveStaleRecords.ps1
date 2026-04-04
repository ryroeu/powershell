<#
.SYNOPSIS
    Removes DNS stale records.
#>

# Find DNS A Records older than 14 days
$Records = Get-DnsServerResourceRecord -ComputerName DCName -ZoneName "ad.domain.com" -RRType "A" | Where-Object {($_.Timestamp -le (Get-Date).adddays(-14)) -AND ($_.Timestamp -like "*/*")}
# Remove the Records
Remove-DnsServerResourceRecord $Records