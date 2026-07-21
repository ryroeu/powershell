<#
.SYNOPSIS
    Deprovisions an Active Directory user and optional on-premises Exchange/file resources.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Identity,

    [string[]]$UserDataRoot,

    [string]$ProfileScriptRoot,

    [switch]$DisableMailbox,

    [switch]$RemoveAdUser
)

$user = Get-ADUser -Identity $Identity -ErrorAction Stop
$targets = [Collections.Generic.List[string]]::new()

foreach ($root in $UserDataRoot) {
    $targets.Add((Join-Path -Path $root -ChildPath $user.SamAccountName))
}
if ($ProfileScriptRoot) {
    $targets.Add((Join-Path -Path $ProfileScriptRoot -ChildPath "$($user.SamAccountName).xml"))
}

foreach ($target in $targets) {
    if ((Test-Path -LiteralPath $target) -and $PSCmdlet.ShouldProcess($target, 'Remove user data')) {
        Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
    }
}

if ($DisableMailbox) {
    if (-not (Get-Command Disable-Mailbox -ErrorAction SilentlyContinue)) {
        throw 'Disable-Mailbox is unavailable. Connect to on-premises Exchange PowerShell first.'
    }
    if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Disable on-premises Exchange mailbox')) {
        Disable-Mailbox -Identity $user.SamAccountName -Confirm:$false -ErrorAction Stop
    }
}

if ($RemoveAdUser -and $PSCmdlet.ShouldProcess($user.DistinguishedName, 'Remove Active Directory user')) {
    Remove-ADUser -Identity $user -Confirm:$false -ErrorAction Stop
}

[pscustomobject]@{
    SamAccountName   = $user.SamAccountName
    DataTargets      = $targets.ToArray()
    MailboxRequested = $DisableMailbox.IsPresent
    RemovalRequested = $RemoveAdUser.IsPresent
}
