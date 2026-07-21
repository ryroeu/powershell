<#
.SYNOPSIS
    Creates and returns a PowerShell remoting session.
#>

[CmdletBinding(DefaultParameterSetName = 'WSMan')]
param(
    [Parameter(Mandatory, ParameterSetName = 'WSMan')]
    [string]$ComputerName,

    [Parameter(ParameterSetName = 'WSMan')]
    [pscredential]$Credential,

    [Parameter(Mandatory, ParameterSetName = 'SSH')]
    [string]$HostName,

    [Parameter(Mandatory, ParameterSetName = 'SSH')]
    [string]$UserName,

    [Parameter(ParameterSetName = 'SSH')]
    [string]$KeyFilePath
)

if ($PSCmdlet.ParameterSetName -eq 'SSH') {
    $parameters = @{ HostName = $HostName; UserName = $UserName }
    if ($KeyFilePath) {
        $parameters.KeyFilePath = $KeyFilePath
    }
    New-PSSession @parameters
}
else {
    $parameters = @{ ComputerName = $ComputerName }
    if ($Credential) {
        $parameters.Credential = $Credential
    }
    New-PSSession @parameters
}
