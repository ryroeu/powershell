<#
.SYNOPSIS
Renames an Active Directory replication site.

.DESCRIPTION
Looks up an existing Active Directory site and renames the underlying directory object
to the new site name. The script validates that the source site exists and that the
target name is not already in use before making the change.

.PARAMETER Identity
The current site name or distinguished name.

.PARAMETER NewName
The new name to assign to the site.

.PARAMETER Server
Optional domain controller or AD DS instance to target.

.PARAMETER Credential
Optional credentials with permission to rename the site.

.PARAMETER PassThru
Returns the renamed site object after the change completes.

.EXAMPLE
.\ADSiteRename.ps1 -Identity "Default-First-Site-Name" -NewName "Paris"

.EXAMPLE
.\ADSiteRename.ps1 -Identity "CN=London,CN=Sites,CN=Configuration,DC=contoso,DC=com" -NewName "Berlin" -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Identity,

    [Parameter(Mandatory, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$NewName,

    [Parameter()]
    [string]$Server,

    [Parameter()]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter()]
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'

if ($Identity -eq $NewName) {
    throw "The new site name must be different from the current site name."
}

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw "The ActiveDirectory module is required to rename an Active Directory site."
}

Import-Module ActiveDirectory -ErrorAction Stop

$adParams = @{}
if ($PSBoundParameters.ContainsKey('Server')) {
    $adParams.Server = $Server
}
if ($PSBoundParameters.ContainsKey('Credential')) {
    $adParams.Credential = $Credential
}

$site = Get-ADReplicationSite -Identity $Identity @adParams -ErrorAction Stop

try {
    $null = Get-ADReplicationSite -Identity $NewName @adParams -ErrorAction Stop
    throw "An Active Directory site named '$NewName' already exists."
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    # Expected when the destination name is available.
}

$target = $site.DistinguishedName
$action = "Rename Active Directory site '$($site.Name)' to '$NewName'"

if ($PSCmdlet.ShouldProcess($target, $action)) {
    Rename-ADObject -Identity $site.DistinguishedName -NewName $NewName @adParams -Confirm:$false

    if ($PassThru) {
        Get-ADReplicationSite -Identity $NewName @adParams
    }
}
