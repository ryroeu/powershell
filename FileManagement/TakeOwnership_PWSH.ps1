<#
.SYNOPSIS
    Sets the built-in Administrators group as owner and grants it full control.
#>

#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ })]
    [string]$Path,

    [switch]$Recurse
)

if (-not $IsWindows) { throw 'This script requires Windows.' }
$administratorSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
$administratorAccount = $administratorSid.Translate([Security.Principal.NTAccount])

$items = @((Get-Item -LiteralPath $Path -Force -ErrorAction Stop))
if ($Recurse) {
    $items += Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
}

$processed = 0
$failed = 0
foreach ($item in $items) {
    if (-not $PSCmdlet.ShouldProcess($item.FullName, 'Set owner and grant Administrators full control')) { continue }
    try {
        $acl = Get-Acl -LiteralPath $item.FullName -ErrorAction Stop
        $acl.SetOwner($administratorSid)
        $inheritance = if ($item.PSIsContainer) {
            [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
        }
        else {
            [Security.AccessControl.InheritanceFlags]::None
        }
        $rule = [Security.AccessControl.FileSystemAccessRule]::new(
            $administratorAccount,
            [Security.AccessControl.FileSystemRights]::FullControl,
            $inheritance,
            [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AccessControlType]::Allow
        )
        $acl.SetAccessRule($rule)
        Set-Acl -LiteralPath $item.FullName -AclObject $acl -ErrorAction Stop
        $processed++
    }
    catch {
        $failed++
        Write-Warning "Could not update '$($item.FullName)': $($_.Exception.Message)"
    }
}

[pscustomobject]@{ Path = (Resolve-Path -LiteralPath $Path).Path; Processed = $processed; Failed = $failed }
