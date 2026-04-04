<# 
.SYNOPSIS
  Retrieve Microsoft 365 service endpoints (URLs/IPs/ports) from endpoints.office.com (JSON).

.EXAMPLE
  .\O365GetUrlIpPortInfo.ps1 -Category Optimize -OutCsv .\o365_endpoints_optimize.csv
#>
[CmdletBinding()]
param(
  [ValidateSet('Optimize','Allow','Default','All')] [string] $Category = 'Optimize',
  [string] $ServiceArea,            # e.g. 'Exchange','SharePoint','Common'
  [string] $OutCsv,                 # optional export
  [switch] $IncludeIps              # include IPs (can be verbose)
)
$ErrorActionPreference = 'Stop'

$crid = (New-Guid).Guid
$base = "https://endpoints.office.com"

$version = Invoke-RestMethod "$base/version/worldwide?clientrequestid=$crid"
$data    = Invoke-RestMethod "$base/endpoints/worldwide?clientrequestid=$crid"

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

$proj | Sort-Object serviceArea,id | Format-Table -AutoSize

if ($OutCsv) {
  $proj | Export-Csv -NoTypeInformation -Path $OutCsv -Encoding UTF8
  Write-Host "Exported -> $OutCsv" -ForegroundColor Green
}
Write-Host "Done." -ForegroundColor Green
Disconnect-MgGraph -Confirm:$false