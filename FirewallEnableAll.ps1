<#
.SYNOPSIS
    Manages firewall enable all.
#>

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True