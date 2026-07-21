<# 
.SYNOPSIS
  Retrieve Microsoft 365 service endpoints (URLs/IPs/ports) from endpoints.office.com (JSON).

.EXAMPLE
  .\O365GetUrlIpPortInfo.ps1 -Category Optimize -OutCsv .\o365_endpoints_optimize.csv
#>
[CmdletBinding()]
param(
    [ValidateSet('Optimize', 'Allow', 'Default', 'All')] [string] $Category = 'Optimize',
    [string] $ServiceArea,            # e.g. 'Exchange','SharePoint','Common'
    [string] $OutCsv,                 # optional export
    [switch] $IncludeIps              # include IPs (can be verbose)
)
$ErrorActionPreference = 'Stop'

$crid = (New-Guid).Guid
$base = "https://endpoints.office.com"

$null = Invoke-RestMethod "$base/version/worldwide?clientrequestid=$crid"
$data = Invoke-RestMethod "$base/endpoints/worldwide?clientrequestid=$crid"

if ($Category -ne 'All') {
    $data = $data | Where-Object { $_.category -eq $Category }
}
if ($ServiceArea) {
    $data = $data | Where-Object { $_.serviceArea -eq $ServiceArea }
}

$proj = $data | ForEach-Object {
    [PSCustomObject]@{
        id          = $_.id
        category    = $_.category
        serviceArea = $_.serviceArea
        urls        = ($_.urls -join ';')
        tcpPorts    = $_.tcpPorts
        udpPorts    = $_.udpPorts
        ips         = if ($IncludeIps) { @($_.ips) -join ';' } else { $null }
    }
}

$results = @($proj | Sort-Object serviceArea, id)

if ($OutCsv) {
    $results | Export-Csv -NoTypeInformation -LiteralPath $OutCsv -Encoding utf8NoBOM
}
$results
