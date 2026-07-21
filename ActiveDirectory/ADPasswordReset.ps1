<#
.SYNOPSIS
    Resets an Active Directory user's password and optionally generates a temporary password.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Generate')]
param(
    [Parameter(Mandatory)]
    [string]$UserName,

    [Parameter(Mandatory, ParameterSetName = 'Supplied')]
    [securestring]$NewPassword,

    [Parameter(ParameterSetName = 'Generate')]
    [ValidateRange(12, 128)]
    [int]$GeneratedPasswordLength = 20,

    [bool]$ChangePasswordAtLogon = $true
)

$plainTextPassword = $null
if ($PSCmdlet.ParameterSetName -eq 'Generate') {
    $characterSets = @(
        'ABCDEFGHJKLMNPQRSTUVWXYZ',
        'abcdefghijkmnopqrstuvwxyz',
        '23456789',
        '!@$%*-_=+?'
    )
    $characters = [Collections.Generic.List[char]]::new()
    foreach ($set in $characterSets) {
        $characters.Add($set[[Security.Cryptography.RandomNumberGenerator]::GetInt32($set.Length)])
    }
    $allCharacters = $characterSets -join ''
    while ($characters.Count -lt $GeneratedPasswordLength) {
        $characters.Add($allCharacters[[Security.Cryptography.RandomNumberGenerator]::GetInt32($allCharacters.Length)])
    }
    $shuffled = $characters | Sort-Object { [Security.Cryptography.RandomNumberGenerator]::GetInt32([int]::MaxValue) }
    $plainTextPassword = -join $shuffled
    $NewPassword = [securestring]::new()
    foreach ($character in $plainTextPassword.ToCharArray()) { $NewPassword.AppendChar($character) }
    $NewPassword.MakeReadOnly()
}

if ($PSCmdlet.ShouldProcess($UserName, 'Reset Active Directory password')) {
    Set-ADAccountPassword -Identity $UserName -NewPassword $NewPassword -Reset -ErrorAction Stop
    Set-ADUser -Identity $UserName -ChangePasswordAtLogon $ChangePasswordAtLogon -ErrorAction Stop

    [pscustomobject]@{
        UserName              = $UserName
        PasswordReset         = $true
        ChangeAtNextLogon     = $ChangePasswordAtLogon
        GeneratedPassword     = $plainTextPassword
    }
}
