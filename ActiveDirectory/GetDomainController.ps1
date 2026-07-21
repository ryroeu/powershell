<#
.SYNOPSIS
    Retrieves Active Directory domain controllers or the PDC emulator.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$DomainName,

    [switch]$PDCEmulatorOnly
)

if ($PDCEmulatorOnly) {
    if ($DomainName) { (Get-ADDomain -Identity $DomainName).PDCEmulator } else { (Get-ADDomain).PDCEmulator }
}
else {
    $parameters = @{ Filter = '*' }
    if ($DomainName) { $parameters.DomainName = $DomainName }
    Get-ADDomainController @parameters
}
