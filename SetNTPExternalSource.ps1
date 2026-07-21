<#
.SYNOPSIS
    Configures Windows Time to use one or more external NTP peers.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string[]]$Peer,

    [switch]$Reliable
)

$peerList = $Peer -join ' '
if ($PSCmdlet.ShouldProcess('Windows Time service', "Set manual peers to '$peerList'")) {
    & "$env:SystemRoot\System32\w32tm.exe" /config "/manualpeerlist:$peerList" /syncfromflags:manual "/reliable:$($Reliable.IsPresent.ToString().ToUpperInvariant())" /update
    if ($LASTEXITCODE -ne 0) {
        throw "w32tm.exe failed with exit code $LASTEXITCODE."
    }
    Restart-Service -Name W32Time -ErrorAction Stop
    & "$env:SystemRoot\System32\w32tm.exe" /resync
}
