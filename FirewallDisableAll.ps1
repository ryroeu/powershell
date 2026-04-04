<#
.SYNOPSIS
    Manages firewall disable all.
#>

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False