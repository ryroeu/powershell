<#
.SYNOPSIS
    Tests pester.
#>

Describe "Invoke-RestMethod Responses" {
    Context "Internet Connectivity" {
        It "Google is Resolvable" {
            $online = Invoke-WebRequest -Uri "https://google.com/"
            $online.StatusCode
        }
        It "Plex is Resolvable" {
            $plex = Invoke-WebRequest -Uri "https://status.plex.tv/api/v2/status.json"
            $plex.Status.Description
        }
    }
}