<#
.SYNOPSIS
    Exports running Windows services to an HTML report.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path $PWD 'RunningServices.html'),

    [string]$ComputerName = $env:COMPUTERNAME,

    [pscredential]$Credential
)

if (-not $IsWindows) { throw 'This script requires Windows.' }

$isLocal = $ComputerName -in '.', 'localhost', $env:COMPUTERNAME
if ($isLocal) {
    $services = Get-Service | Where-Object Status -EQ 'Running'
}
else {
    $parameters = @{ ComputerName = $ComputerName; ErrorAction = 'Stop' }
    if ($Credential) { $parameters.Credential = $Credential }
    $services = Invoke-Command @parameters -ScriptBlock {
        Get-Service | Where-Object Status -EQ 'Running'
    }
}

$services |
    Select-Object Name, DisplayName, Status, StartType |
    ConvertTo-Html -Title "Running services on $ComputerName" -PreContent "<h1>Running services on $ComputerName</h1>" |
    Set-Content -LiteralPath $OutputPath -Encoding utf8NoBOM
Get-Item -LiteralPath $OutputPath
