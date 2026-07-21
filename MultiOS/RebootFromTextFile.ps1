<#
.SYNOPSIS
    Restarts remote Windows computers listed in a text file.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ComputerListPath,

    [Parameter(Mandatory)]
    [pscredential]$Credential,

    [switch]$UseSsl,

    [switch]$Wait,

    [ValidateRange(1, 3600)]
    [int]$TimeoutSeconds = 300
)

$computers = Get-Content -LiteralPath $ComputerListPath |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ } |
    Sort-Object -Unique

foreach ($computer in $computers) {
    if (-not $PSCmdlet.ShouldProcess($computer, 'Restart remote computer')) { continue }

    try {
        $parameters = @{
            ComputerName = $computer
            Credential   = $Credential
            UseSSL       = $UseSsl
            Force        = $true
            ErrorAction  = 'Stop'
        }
        if ($Wait) {
            $parameters.Wait = $true
            $parameters.Timeout = $TimeoutSeconds
            $parameters.For = 'PowerShell'
        }
        Restart-Computer @parameters
        [pscustomobject]@{ ComputerName = $computer; RestartRequested = $true; Error = $null }
    }
    catch {
        [pscustomobject]@{ ComputerName = $computer; RestartRequested = $false; Error = $_.Exception.Message }
    }
}
