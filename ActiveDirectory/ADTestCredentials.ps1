<#
.SYNOPSIS
    Tests credentials by binding to an LDAP server.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Server,

    [Parameter(Mandatory)]
    [pscredential]$Credential,

    [ValidateRange(1, 65535)]
    [int]$Port = 389,

    [switch]$UseSsl
)

Add-Type -AssemblyName System.DirectoryServices.Protocols
$identifier = [System.DirectoryServices.Protocols.LdapDirectoryIdentifier]::new($Server, $Port, $false, $false)
$connection = [System.DirectoryServices.Protocols.LdapConnection]::new($identifier)
$connection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Negotiate
$connection.Credential = $Credential.GetNetworkCredential()
$connection.SessionOptions.SecureSocketLayer = $UseSsl

try {
    $connection.Bind()
    [pscustomobject]@{ Server = $Server; Port = $Port; UserName = $Credential.UserName; Authenticated = $true; Error = $null }
}
catch {
    [pscustomobject]@{ Server = $Server; Port = $Port; UserName = $Credential.UserName; Authenticated = $false; Error = $_.Exception.Message }
}
finally {
    $connection.Dispose()
}
