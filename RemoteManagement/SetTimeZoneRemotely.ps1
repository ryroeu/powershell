<#
.SYNOPSIS
    Sets the Windows time zone on one or more remote computers.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('Name')]
    [string[]]$ComputerName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TimeZoneId,

    [pscredential]$Credential
)

begin {
    if (-not $IsWindows) {
        throw 'This script requires Windows.'
    }
}

process {
    $targets = if ($ComputerName) {
        $ComputerName
    }
    else {
        if (-not (Get-Command Get-ADComputer -ErrorAction SilentlyContinue)) {
            throw 'Supply -ComputerName or install/import the ActiveDirectory module.'
        }
        Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
    }

    foreach ($computer in $targets) {
        if (-not $PSCmdlet.ShouldProcess($computer, "Set time zone to '$TimeZoneId'")) {
            continue
        }

        $parameters = @{ ComputerName = $computer; ErrorAction = 'Stop' }
        if ($Credential) { $parameters.Credential = $Credential }
        Invoke-Command @parameters -ScriptBlock {
            Set-TimeZone -Id $using:TimeZoneId -PassThru
        }
    }
}
