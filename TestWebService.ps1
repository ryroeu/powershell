<#
.SYNOPSIS
    Tests HTTP endpoints and returns status information.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [uri[]]$Uri,

    [ValidateRange(1, 300)]
    [int]$TimeoutSeconds = 30
)

process {
    foreach ($endpoint in $Uri) {
        $stopwatch = [Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-WebRequest -Uri $endpoint -Method Head -TimeoutSec $TimeoutSeconds -ErrorAction Stop
            [pscustomobject]@{
                Uri          = $endpoint
                IsReachable  = $true
                StatusCode   = [int]$response.StatusCode
                Status       = $response.StatusDescription
                ElapsedMs    = $stopwatch.ElapsedMilliseconds
                ErrorMessage = $null
            }
        }
        catch {
            [pscustomobject]@{
                Uri          = $endpoint
                IsReachable  = $false
                StatusCode   = $null
                Status       = $null
                ElapsedMs    = $stopwatch.ElapsedMilliseconds
                ErrorMessage = $_.Exception.Message
            }
        }
        finally {
            $stopwatch.Stop()
        }
    }
}
