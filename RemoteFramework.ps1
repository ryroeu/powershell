<#
.SYNOPSIS
    Invokes a caller-supplied script block through WinRM, SSH, or existing PowerShell sessions.
#>

#Requires -Version 7.0

[CmdletBinding(DefaultParameterSetName = 'WinRM', SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory, ParameterSetName = 'WinRM')]
    [string[]]$ComputerName,

    [Parameter(ParameterSetName = 'WinRM')]
    [pscredential]$Credential,

    [Parameter(ParameterSetName = 'WinRM')]
    [switch]$UseSsl,

    [Parameter(Mandatory, ParameterSetName = 'Ssh')]
    [string[]]$HostName,

    [Parameter(Mandatory, ParameterSetName = 'Ssh')]
    [string]$UserName,

    [Parameter(ParameterSetName = 'Ssh')]
    [string]$KeyFilePath,

    [Parameter(ParameterSetName = 'Ssh')]
    [ValidateRange(1, 65535)]
    [int]$Port = 22,

    [Parameter(Mandatory, ParameterSetName = 'Session')]
    [Management.Automation.Runspaces.PSSession[]]$Session,

    [object[]]$ArgumentList,

    [ValidateRange(1, 1024)]
    [int]$ThrottleLimit = 32
)

$createdSessions = [Collections.Generic.List[Management.Automation.Runspaces.PSSession]]::new()
try {
    $sessions = if ($PSCmdlet.ParameterSetName -eq 'Session') {
        @($Session | Where-Object State -eq 'Opened')
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'WinRM') {
        foreach ($computer in $ComputerName) {
            $parameters = @{ ComputerName = $computer; UseSSL = $UseSsl; ErrorAction = 'Stop' }
            if ($Credential) { $parameters.Credential = $Credential }
            $newSession = New-PSSession @parameters
            $createdSessions.Add($newSession)
            $newSession
        }
    }
    else {
        foreach ($hostTarget in $HostName) {
            $parameters = @{ HostName = $hostTarget; UserName = $UserName; Port = $Port; ErrorAction = 'Stop' }
            if ($KeyFilePath) { $parameters.KeyFilePath = $KeyFilePath }
            $newSession = New-PSSession @parameters
            $createdSessions.Add($newSession)
            $newSession
        }
    }

    if (-not $sessions) { throw 'No open PowerShell sessions are available.' }
    $targetNames = $sessions.ComputerName -join ', '
    if ($PSCmdlet.ShouldProcess($targetNames, 'Invoke caller-supplied script block')) {
        Invoke-Command -Session $sessions -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -ThrottleLimit $ThrottleLimit -ErrorAction Stop
    }
}
finally {
    if ($createdSessions.Count -gt 0) {
        $createdSessions | Remove-PSSession
    }
}
