<#
.SYNOPSIS
    Configures the CredSSP encryption-oracle remediation policy.
.DESCRIPTION
    The vulnerable value (2) should only be used as a short-lived compatibility mitigation.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateSet(0, 1, 2)]
    [int]$ProtectionLevel = 0
)

$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters'
if ($PSCmdlet.ShouldProcess('Local computer', "Set AllowEncryptionOracle to $ProtectionLevel")) {
    $null = New-Item -Path $path -Force
    Set-ItemProperty -LiteralPath $path -Name AllowEncryptionOracle -Value $ProtectionLevel -Type DWord
    if ($ProtectionLevel -eq 2) {
        Write-Warning 'ProtectionLevel 2 permits vulnerable CredSSP connections. Revert to 0 after affected hosts are patched.'
    }
}
