<#
.SYNOPSIS
    Moves an Active Directory object to another organizational unit.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [Parameter(Mandatory)]
    [string]$TargetPath,

    [string]$Server,

    [pscredential]$Credential
)

$parameters = @{ Identity = $Identity; TargetPath = $TargetPath }
if ($Server) { $parameters.Server = $Server }
if ($Credential) { $parameters.Credential = $Credential }
if ($PSCmdlet.ShouldProcess($Identity, "Move Active Directory object to '$TargetPath'")) {
    Move-ADObject @parameters -PassThru
}
