<#
.SYNOPSIS
    Removes an AppX package from local users who are not administrators.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Name
)

$administratorNames = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop |
        ForEach-Object { ($_.Name -split '\\')[-1] })

foreach ($user in Get-LocalUser | Where-Object Enabled) {
    if ($user.Name -in $administratorNames) {
        Write-Verbose "Skipping administrator '$($user.Name)'."
        continue
    }

    $packages = @(Get-AppxPackage -User $user.Name -Name $Name -ErrorAction SilentlyContinue)
    foreach ($package in $packages) {
        if ($PSCmdlet.ShouldProcess("$($user.Name): $($package.Name)", 'Remove AppX package')) {
            Remove-AppxPackage -Package $package.PackageFullName -User $user.SID -ErrorAction Stop
        }
    }
}
