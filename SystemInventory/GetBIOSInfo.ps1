<#
.SYNOPSIS
    Retrieves BIOS information from a Windows computer.
#>

[CmdletBinding()]
param(
    [string]$ComputerName,

    [pscredential]$Credential
)

$session = $null
try {
    $parameters = @{ ClassName = 'Win32_BIOS' }
    if ($ComputerName) {
        $sessionParameters = @{ ComputerName = $ComputerName }
        if ($Credential) { $sessionParameters.Credential = $Credential }
        $session = New-CimSession @sessionParameters
        $parameters.CimSession = $session
    }
    Get-CimInstance @parameters | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate, SerialNumber
}
finally {
    if ($session) { Remove-CimSession -CimSession $session }
}
