<#
.SYNOPSIS
    Configures the default Active Directory domain password and lockout policy.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$DomainName,

    [timespan]$LockoutDuration = '00:40:00',

    [timespan]$LockoutObservationWindow = '00:20:00',

    [ValidateRange(0, 999)]
    [int]$LockoutThreshold = 5,

    [timespan]$MaxPasswordAge = '42.00:00:00',

    [timespan]$MinPasswordAge = '1.00:00:00',

    [ValidateRange(0, 128)]
    [int]$MinPasswordLength = 12,

    [ValidateRange(0, 1024)]
    [int]$PasswordHistoryCount = 24,

    [bool]$ComplexityEnabled = $true,

    [bool]$ReversibleEncryptionEnabled = $false
)

$identity = if ($DomainName) { $DomainName } else { (Get-ADDomain -ErrorAction Stop).DNSRoot }
if ($MaxPasswordAge -lt $MinPasswordAge) {
    throw '-MaxPasswordAge cannot be shorter than -MinPasswordAge.'
}
if ($LockoutThreshold -eq 0 -and ($LockoutDuration -ne [timespan]::Zero -or $LockoutObservationWindow -ne [timespan]::Zero)) {
    throw 'Use zero lockout duration and observation window when -LockoutThreshold is zero.'
}

$parameters = @{
    Identity                    = $identity
    LockoutDuration             = $LockoutDuration
    LockoutObservationWindow    = $LockoutObservationWindow
    LockoutThreshold            = $LockoutThreshold
    ComplexityEnabled           = $ComplexityEnabled
    ReversibleEncryptionEnabled = $ReversibleEncryptionEnabled
    MinPasswordLength           = $MinPasswordLength
    MinPasswordAge              = $MinPasswordAge
    MaxPasswordAge              = $MaxPasswordAge
    PasswordHistoryCount        = $PasswordHistoryCount
    ErrorAction                 = 'Stop'
}

if ($PSCmdlet.ShouldProcess($identity, 'Set default domain password policy')) {
    Set-ADDefaultDomainPasswordPolicy @parameters
}
Get-ADDefaultDomainPasswordPolicy -Identity $identity
