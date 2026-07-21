<#
.SYNOPSIS
    Starts BitLocker decryption for a volume.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidatePattern('^[A-Za-z]:$')]
    [string]$MountPoint = 'C:'
)

if ($PSCmdlet.ShouldProcess($MountPoint, 'Disable BitLocker and decrypt the volume')) {
    Disable-BitLocker -MountPoint $MountPoint
}
