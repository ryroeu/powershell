<#
.SYNOPSIS
    Manages active directory site location.
#>

# Change Site Location
Set-ADReplicationSite "CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=Lucernpub,DC=com" -Location "New location here”
