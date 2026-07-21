<#
.SYNOPSIS
    Imports a certificate into a Windows certificate store.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$FilePath,

    [string]$CertStoreLocation = 'Cert:\LocalMachine\Root'
)

if ($PSCmdlet.ShouldProcess($CertStoreLocation, "Import certificate '$FilePath'")) {
    Import-Certificate -FilePath $FilePath -CertStoreLocation $CertStoreLocation
}
