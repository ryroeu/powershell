<#
.SYNOPSIS
    Sets the trusted state of a PSResourceGet repository.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$Name = 'PSGallery',

    [bool]$Trusted = $true
)

if ($PSCmdlet.ShouldProcess($Name, "Set repository trusted state to $Trusted")) {
    Set-PSResourceRepository -Name $Name -Trusted:$Trusted -PassThru
}
