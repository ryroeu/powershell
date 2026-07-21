<#
.SYNOPSIS
    Calls the Google Geolocation API and returns the estimated coordinates and accuracy.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ApiKey,

    [string]$RequestBodyPath = (Join-Path $PSScriptRoot 'GeoLocate.json')
)

$uri = 'https://www.googleapis.com/geolocation/v1/geolocate?key={0}' -f [uri]::EscapeDataString($ApiKey)
$body = Get-Content -LiteralPath $RequestBodyPath -Raw -ErrorAction Stop
$location = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/json'

$meters = [math]::Round([double]$location.accuracy, 2)
[pscustomobject]@{
    Latitude       = [math]::Round([double]$location.location.lat, 4)
    Longitude      = [math]::Round([double]$location.location.lng, 4)
    AccuracyMeters = $meters
    AccuracyMiles  = [math]::Round($meters / 1609.344, 2)
}
