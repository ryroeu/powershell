<#
.SYNOPSIS
    Configures a static IPv4 address, DNS servers, and computer name.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$InterfaceAlias,

    [Parameter(Mandatory)]
    [ipaddress]$IPAddress,

    [ValidateRange(1, 32)]
    [int]$PrefixLength = 24,

    [Parameter(Mandatory)]
    [ipaddress]$DefaultGateway,

    [Parameter(Mandatory)]
    [ipaddress[]]$DnsServerAddress,

    [Parameter(Mandatory)]
    [string]$NewComputerName,

    [switch]$Restart
)

$target = "$InterfaceAlias on $env:COMPUTERNAME"
if ($PSCmdlet.ShouldProcess($target, 'Configure static IPv4 address and DNS servers')) {
    New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway -AddressFamily IPv4
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DnsServerAddress
}

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Rename computer to '$NewComputerName'")) {
    Rename-Computer -NewName $NewComputerName -Force -Restart:$Restart
}
