<#
.SYNOPSIS
    Sets the Windows computer description on a remote computer.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [string[]]$ComputerName,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Description,

    [pscredential]$Credential
)

foreach ($computer in $ComputerName) {
    if (-not $PSCmdlet.ShouldProcess($computer, "Set computer description to '$Description'")) {
        continue
    }

    $parameters = @{
        ComputerName = $computer
        ScriptBlock  = {
            param($NewDescription)
            Get-CimInstance -ClassName Win32_OperatingSystem |
                Set-CimInstance -Property @{ Description = $NewDescription }
        }
        ArgumentList = $Description
    }
    if ($Credential) {
        $parameters.Credential = $Credential
    }
    Invoke-Command @parameters
}
