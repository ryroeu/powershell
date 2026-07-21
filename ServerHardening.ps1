<#
.SYNOPSIS
    Applies a small, explicit Windows Server hardening baseline.
.DESCRIPTION
    Ensures UAC remains enabled, configures a Remote Desktop idle timeout, and optionally adds
    successful change/take-ownership auditing to specified files or directories.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateRange(1, 1440)]
    [int]$RemoteDesktopIdleMinutes = 20,

    [string[]]$AuditPath
)

if (-not $IsWindows) { throw 'This script requires Windows.' }

$systemPolicyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
if ($PSCmdlet.ShouldProcess($systemPolicyPath, 'Enable User Account Control')) {
    Set-ItemProperty -Path $systemPolicyPath -Name EnableLUA -Type DWord -Value 1 -ErrorAction Stop
}

$terminalServicesPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
if ($PSCmdlet.ShouldProcess($terminalServicesPath, "Set idle timeout to $RemoteDesktopIdleMinutes minute(s)")) {
    New-Item -Path $terminalServicesPath -Force | Out-Null
    Set-ItemProperty -Path $terminalServicesPath -Name MaxIdleTime -Type DWord -Value ($RemoteDesktopIdleMinutes * 60000) -ErrorAction Stop
}

$everyoneSid = [Security.Principal.SecurityIdentifier]::new('S-1-1-0')
foreach ($itemPath in $AuditPath) {
    $item = Get-Item -LiteralPath $itemPath -Force -ErrorAction Stop
    $inheritance = if ($item.PSIsContainer) {
        [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
    }
    else {
        [Security.AccessControl.InheritanceFlags]::None
    }
    $rule = [Security.AccessControl.FileSystemAuditRule]::new(
        $everyoneSid,
        [Security.AccessControl.FileSystemRights]'TakeOwnership, ChangePermissions',
        $inheritance,
        [Security.AccessControl.PropagationFlags]::None,
        [Security.AccessControl.AuditFlags]::Success
    )

    if ($PSCmdlet.ShouldProcess($item.FullName, 'Add successful permission-change audit rule')) {
        $acl = Get-Acl -LiteralPath $item.FullName -Audit
        $acl.AddAuditRule($rule)
        Set-Acl -LiteralPath $item.FullName -AclObject $acl -ErrorAction Stop
    }
}
