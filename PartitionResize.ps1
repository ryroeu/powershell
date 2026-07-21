<#
.SYNOPSIS
    Expands a Windows partition to its maximum supported size.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidatePattern('^[A-Za-z]$')]
    [string]$DriveLetter = 'C'
)

$size = Get-PartitionSupportedSize -DriveLetter $DriveLetter
if ($PSCmdlet.ShouldProcess("$DriveLetter`:", "Resize partition to $($size.SizeMax) bytes")) {
    Resize-Partition -DriveLetter $DriveLetter -Size $size.SizeMax
}
