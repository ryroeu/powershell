<#
.SYNOPSIS
    Clears dynamic IPv4 or IPv6 neighbor-cache entries on Windows computers.
.DESCRIPTION
    Uses the NetTCPIP cmdlets locally or through CIM sessions. Permanent entries are excluded unless
    -IncludePermanent is specified.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name')]
    [string[]]$ComputerName = @($env:COMPUTERNAME),

    [string[]]$InterfaceAlias,

    [ipaddress[]]$IPAddress,

    [ValidateSet('IPv4', 'IPv6', 'Both')]
    [string]$AddressFamily = 'IPv4',

    [switch]$IncludePermanent,

    [pscredential]$Credential
)

begin {
    $families = if ($AddressFamily -eq 'Both') { @('IPv4', 'IPv6') } else { @($AddressFamily) }
    $results = [Collections.Generic.List[object]]::new()
}

process {
    foreach ($computer in $ComputerName) {
        $session = $null
        try {
            $isLocal = $computer -in '.', 'localhost', $env:COMPUTERNAME
            if (-not $isLocal) {
                $sessionParameters = @{ ComputerName = $computer }
                if ($Credential) {
                    $sessionParameters.Credential = $Credential
                }
                $session = New-CimSession @sessionParameters
            }

            $cleared = 0
            $failed = 0
            foreach ($family in $families) {
                $getParameters = @{ AddressFamily = $family; ErrorAction = 'Stop' }
                if ($session) {
                    $getParameters.CimSession = $session
                }

                $neighbors = Get-NetNeighbor @getParameters
                if ($InterfaceAlias) {
                    $patterns = $InterfaceAlias
                    $neighbors = $neighbors | Where-Object {
                        $alias = $_.InterfaceAlias
                        @($patterns | Where-Object { $alias -like $_ }).Count -gt 0
                    }
                }
                if ($IPAddress) {
                    $neighbors = $neighbors | Where-Object { $_.IPAddress -in $IPAddress.IPAddressToString }
                }
                if (-not $IncludePermanent) {
                    $neighbors = $neighbors | Where-Object State -NE 'Permanent'
                }
                $neighbors = $neighbors | Where-Object State -In 'Reachable', 'Stale', 'Delay', 'Probe', 'Unknown', 'Unreachable', 'Incomplete'

                foreach ($neighbor in $neighbors | Sort-Object InterfaceIndex, IPAddress -Unique) {
                    $target = '{0}: {1} ({2})' -f $computer, $neighbor.IPAddress, $neighbor.InterfaceAlias
                    if (-not $PSCmdlet.ShouldProcess($target, 'Remove neighbor-cache entry')) {
                        continue
                    }

                    try {
                        $removeParameters = @{
                            InterfaceIndex = $neighbor.InterfaceIndex
                            IPAddress      = $neighbor.IPAddress
                            Confirm        = $false
                            ErrorAction    = 'Stop'
                        }
                        if ($session) {
                            $removeParameters.CimSession = $session
                        }
                        Remove-NetNeighbor @removeParameters
                        $cleared++
                    }
                    catch {
                        $failed++
                        Write-Error -ErrorRecord $_
                    }
                }
            }

            $results.Add([pscustomobject]@{
                    ComputerName = $computer
                    Cleared      = $cleared
                    Failed       = $failed
                })
        }
        finally {
            if ($session) {
                Remove-CimSession -CimSession $session
            }
        }
    }
}

end {
    $results
}
