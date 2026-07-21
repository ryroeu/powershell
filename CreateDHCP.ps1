<#
.SYNOPSIS
    Installs, authorizes, and configures a Windows DHCP Server.
.EXAMPLE
    $scopes = @(
        @{ Name='CorpNet'; StartRange='10.0.0.20'; EndRange='10.0.0.254'; SubnetMask='255.255.255.0'; Router='10.0.0.1'; ExclusionStart='10.0.0.20'; ExclusionEnd='10.0.0.30' }
    )
    ./CreateDHCP.ps1 -ComputerName DHCP1 -DnsName DHCP1.contoso.com -IPAddress 10.0.0.3 -DnsDomain contoso.com -DnsServer 10.0.0.2 -Scope $scopes
#>

#Requires -RunAsAdministrator
#Requires -Modules DhcpServer, ServerManager

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [Parameter(Mandatory)]
    [string]$DnsName,

    [Parameter(Mandatory)]
    [ipaddress]$IPAddress,

    [Parameter(Mandatory)]
    [string]$DnsDomain,

    [Parameter(Mandatory)]
    [ipaddress[]]$DnsServer,

    [Parameter(Mandatory)]
    [hashtable[]]$Scope,

    [pscredential]$DnsUpdateCredential
)

if ($PSCmdlet.ShouldProcess($ComputerName, 'Install DHCP Server role')) {
    Install-WindowsFeature -Name DHCP -ComputerName $ComputerName -IncludeManagementTools -ErrorAction Stop
}

if ($PSCmdlet.ShouldProcess($DnsName, 'Authorize DHCP server in Active Directory')) {
    $authorized = Get-DhcpServerInDC | Where-Object { $_.DnsName -eq $DnsName -or $_.IPAddress -eq $IPAddress.IPAddressToString }
    if (-not $authorized) {
        Add-DhcpServerInDC -DnsName $DnsName -IPAddress $IPAddress -ErrorAction Stop
    }
}

if ($PSCmdlet.ShouldProcess($DnsName, 'Configure DHCP dynamic DNS updates')) {
    Set-DhcpServerv4DnsSetting -ComputerName $ComputerName -DynamicUpdates Always -DeleteDnsRRonLeaseExpiry $true
    if ($DnsUpdateCredential) {
        Set-DhcpServerDnsCredential -ComputerName $ComputerName -Credential $DnsUpdateCredential
    }
}

foreach ($definition in $Scope) {
    foreach ($requiredKey in 'Name', 'StartRange', 'EndRange', 'SubnetMask', 'Router') {
        if (-not $definition.ContainsKey($requiredKey)) {
            throw "Scope definition is missing required key '$requiredKey'."
        }
    }

    $scopeId = ([ipaddress]$definition.StartRange).IPAddressToString
    $existing = Get-DhcpServerv4Scope -ComputerName $ComputerName -ErrorAction SilentlyContinue |
        Where-Object Name -eq $definition.Name
    if (-not $existing -and $PSCmdlet.ShouldProcess("$ComputerName :: $($definition.Name)", 'Create DHCP scope')) {
        Add-DhcpServerv4Scope -ComputerName $ComputerName -Name $definition.Name -StartRange $definition.StartRange -EndRange $definition.EndRange -SubnetMask $definition.SubnetMask -State Active
        $existing = Get-DhcpServerv4Scope -ComputerName $ComputerName -ErrorAction Stop |
            Where-Object Name -eq $definition.Name
    }
    if ($existing) {
        $scopeId = $existing.ScopeId
    }

    if ($definition.ExclusionStart -and $definition.ExclusionEnd -and $PSCmdlet.ShouldProcess("$ComputerName :: $scopeId", 'Create DHCP exclusion range')) {
        Add-DhcpServerv4ExclusionRange -ComputerName $ComputerName -ScopeId $scopeId -StartRange $definition.ExclusionStart -EndRange $definition.ExclusionEnd
    }

    if ($PSCmdlet.ShouldProcess("$ComputerName :: $scopeId", 'Configure DHCP router and DNS options')) {
        Set-DhcpServerv4OptionValue -ComputerName $ComputerName -ScopeId $scopeId -Router $definition.Router -DnsDomain $DnsDomain -DnsServer $DnsServer
    }
}

Get-DhcpServerv4Scope -ComputerName $ComputerName
