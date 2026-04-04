<#
.SYNOPSIS
    Exports DNS zone records.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path $PWD -ChildPath 'DNSRecords.csv'),
    [switch]$ShowGridView
)

$results = foreach ($zone in Get-DnsServerZone) {
    foreach ($record in Get-DnsServerResourceRecord -ZoneName $zone.ZoneName) {
        [pscustomobject]@{
            ZoneName   = $zone.ZoneName
            HostName   = $record.HostName
            RecordType = $record.RecordType
            RecordData = $record.RecordData.ToString()
        }
    }
}

if ($ShowGridView) {
    if (Get-Command -Name Out-GridView -ErrorAction SilentlyContinue) {
        $results | Out-GridView -Title 'DNS Zone Records'
    }
    else {
        Write-Warning 'Out-GridView is not available in this session. Skipping the grid view display.'
    }
}

$results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
$results
