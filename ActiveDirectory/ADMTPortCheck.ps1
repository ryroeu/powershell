<#
.SYNOPSIS
    Tests the TCP ports commonly required by Active Directory Migration Tool operations.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Target,

    [ValidateRange(1, 65535)]
    [int[]]$Port = @(53, 88, 135, 389, 445, 636, 3268, 3269),

    [ValidateRange(100, 60000)]
    [int]$TimeoutMilliseconds = 3000
)

foreach ($number in $Port) {
    $client = [Net.Sockets.TcpClient]::new()
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    try {
        $task = $client.ConnectAsync($Target, $number)
        $connected = $task.Wait($TimeoutMilliseconds) -and $client.Connected
        [pscustomobject]@{
            Target    = $Target
            Protocol  = 'TCP'
            Port      = $number
            Reachable = $connected
            ElapsedMs = $stopwatch.ElapsedMilliseconds
        }
    }
    catch {
        [pscustomobject]@{
            Target    = $Target
            Protocol  = 'TCP'
            Port      = $number
            Reachable = $false
            ElapsedMs = $stopwatch.ElapsedMilliseconds
        }
    }
    finally {
        $stopwatch.Stop()
        $client.Dispose()
    }
}
