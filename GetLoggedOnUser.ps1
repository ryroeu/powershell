<#
.SYNOPSIS
    Retrieves Terminal Services sessions from a Windows computer.
#>

[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [pscredential]$Credential
)

$sessionParameters = @{ ComputerName = $ComputerName }
if ($Credential) {
    $sessionParameters.Credential = $Credential
}

$session = New-CimSession @sessionParameters
try {
    Get-CimInstance -CimSession $session -Namespace 'root/CIMV2/TerminalServices' -ClassName Win32_TSSession |
        Select-Object UserName, SessionId, State, ClientName, SessionType, ConnectTime, DisconnectTime, LogonTime
}
finally {
    Remove-CimSession -CimSession $session
}
