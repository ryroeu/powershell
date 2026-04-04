<#
.SYNOPSIS
    Manages geolocation.
#>

# Enter your Google GeoLocation API Key
$apikey = "YOUR-API-KEY-HERE"

# Define the REST API URL and the body of the request
$Url = "https://www.googleapis.com/geolocation/v1/geolocate?key=$apikey"
$Body = Get-Content -Path .\GeoLocate.json

# Invoke the REST API and split the coords into latitude and longitude then round to 4 decimal places
$location = Invoke-RestMethod -Method 'Post' -Uri $url -Body $body 
$locationLatRaw = ($location).location.lat
$locationLngRaw = ($location).location.lng
$locationLat = [math]::Round($locationLatRaw, 4)
$locationLng = [math]::Round($locationLngRaw, 4)

# Convert the accuracy from meters to miles
# Define the conversion rate (meters per mile)
$metersPerMile = 1609.34
# Convert meters to miles and round to 2 decimal places
$metersRaw = $location.accuracy
$milesRaw = $meters / $metersPerMile
$meters = [math]::Round($metersRaw, 2)
$miles = [math]::Round($milesRaw, 2)

# Display the results
Write-Host "Latitude: $locationLat"
Write-Host "Longitude: $locationLng"
Write-Host "Accuracy in meters: $meters"
Write-Host "Accuracy in miles: $miles"
