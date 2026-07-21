<#
.SYNOPSIS
    Stops a named process through PowerShell remoting.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'WSMan')]
param(
    [Parameter(Mandatory)]
    [string]$ProcessName,

    [Parameter(Mandatory, ParameterSetName = 'WSMan')]
    [string[]]$ComputerName,

    [Parameter(ParameterSetName = 'WSMan')]
    [pscredential]$Credential,

    [Parameter(Mandatory, ParameterSetName = 'SSH')]
    [string[]]$HostName,

    [Parameter(Mandatory, ParameterSetName = 'SSH')]
    [string]$UserName,

    [Parameter(ParameterSetName = 'SSH')]
    [string]$KeyFilePath,

    [switch]$PassThru,

    [ValidateRange(1, 1024)]
    [int]$ThrottleLimit = 32
)

$targets = if ($PSCmdlet.ParameterSetName -eq 'SSH') { $HostName } else { $ComputerName }
$sessions = [Collections.Generic.List[Management.Automation.Runspaces.PSSession]]::new()
try {
    foreach ($target in $targets) {
        if (-not $PSCmdlet.ShouldProcess($target, "Stop process '$ProcessName'")) {
            continue
        }

        $parameters = if ($PSCmdlet.ParameterSetName -eq 'SSH') {
            @{ HostName = $target; UserName = $UserName }
        }
        else {
            @{ ComputerName = $target }
        }
        if ($Credential) { $parameters.Credential = $Credential }
        if ($KeyFilePath) { $parameters.KeyFilePath = $KeyFilePath }
        $sessions.Add((New-PSSession @parameters))
    }

    if ($sessions.Count -gt 0) {
        Invoke-Command -Session $sessions.ToArray() -ThrottleLimit $ThrottleLimit -ArgumentList $ProcessName, $PassThru.IsPresent -ScriptBlock {
            param($Name, $ReturnProcess)
            Get-Process -Name $Name -ErrorAction Stop |
                Stop-Process -Force -PassThru:$ReturnProcess -Confirm:$false
        }
    }
}
finally {
    if ($sessions.Count -gt 0) { Remove-PSSession -Session $sessions.ToArray() }
}
