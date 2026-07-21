<#
.SYNOPSIS
    Searches every domain in an Active Directory forest for duplicate address values.
.EXAMPLE
    ./ADDuplicateValues.ps1 -Address john@contoso.com -IncludeExchange -IncludeSIP
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Address,

    [pscredential]$Credential,

    [switch]$IncludeExchange,

    [switch]$IncludeSIP,

    [switch]$Contains
)

function ConvertTo-LdapFilterValue {
    param([Parameter(Mandatory)][string]$Value)

    $builder = [Text.StringBuilder]::new()
    foreach ($character in $Value.ToCharArray()) {
        $escaped = switch ($character) {
            '(' { '\28' }
            ')' { '\29' }
            '*' { '\2a' }
            '\' { '\5c' }
            ([char]0) { '\00' }
            default { [string]$character }
        }
        $null = $builder.Append($escaped)
    }
    $builder.ToString()
}

$escapedAddress = ConvertTo-LdapFilterValue -Value $Address
$matchValue = if ($Contains) { "*$escapedAddress*" } else { $escapedAddress }
$clauses = [Collections.Generic.List[string]]::new()
$clauses.Add("(userPrincipalName=$matchValue)")
$clauses.Add("(mail=$matchValue)")

$attributes = [Collections.Generic.List[string]]::new()
foreach ($name in 'UserPrincipalName', 'DisplayName', 'DistinguishedName', 'ObjectClass', 'mail') {
    $attributes.Add($name)
}
if ($IncludeExchange) {
    foreach ($name in 'proxyAddresses', 'msExchRecipientDisplayType', 'msExchRecipientTypeDetails', 'mailNickname', 'targetAddress') {
        $attributes.Add($name)
    }
    $clauses.Add("(proxyAddresses=*:$escapedAddress)")
    $clauses.Add("(targetAddress=*:$escapedAddress)")
}
if ($IncludeSIP) {
    $attributes.Add('msRTCSIP-PrimaryUserAddress')
    $clauses.Add("(msRTCSIP-PrimaryUserAddress=*:$escapedAddress)")
}

$ldapFilter = '(&(|(objectClass=user)(objectClass=group)(objectClass=contact))(|{0}))' -f ($clauses -join '')
foreach ($domain in (Get-ADForest).Domains) {
    $parameters = @{
        Server     = $domain
        LDAPFilter = $ldapFilter
        Properties = $attributes.ToArray()
    }
    if ($Credential) { $parameters.Credential = $Credential }

    Get-ADObject @parameters |
        Select-Object @{Name = 'Domain'; Expression = { $domain } }, $attributes.ToArray()
}
