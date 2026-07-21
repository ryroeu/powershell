<#
.SYNOPSIS
    Tests whether the current Windows identity is a local administrator.
#>

[CmdletBinding()]
param()

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

[pscustomobject]@{
    Identity        = $identity.Name
    IsAdministrator = $isAdministrator
    IsElevated      = $isAdministrator
}
