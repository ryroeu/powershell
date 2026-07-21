<#
.SYNOPSIS
    Clears the local DNS resolver cache on Windows, Linux, or macOS.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

if (-not $PSCmdlet.ShouldProcess([Environment]::MachineName, 'Clear local DNS resolver cache')) { return }

if ($IsWindows) {
    Clear-DnsClientCache -ErrorAction Stop
    $method = 'Clear-DnsClientCache'
}
elseif ($IsMacOS) {
    if ([Environment]::UserName -ne 'root') { throw 'Run this script as root on macOS.' }
    & /usr/bin/dscacheutil -flushcache
    if ($LASTEXITCODE -ne 0) { throw "dscacheutil failed with exit code $LASTEXITCODE." }
    & /usr/bin/killall -HUP mDNSResponder
    if ($LASTEXITCODE -ne 0) { throw "mDNSResponder reload failed with exit code $LASTEXITCODE." }
    $method = 'dscacheutil and mDNSResponder'
}
elseif ($IsLinux) {
    if ([Environment]::UserName -ne 'root') { throw 'Run this script as root on Linux.' }
    if (Get-Command resolvectl -CommandType Application -ErrorAction SilentlyContinue) {
        & resolvectl flush-caches
        $method = 'resolvectl'
    }
    elseif (Get-Command systemctl -CommandType Application -ErrorAction SilentlyContinue) {
        $resolver = @('systemd-resolved', 'nscd', 'dnsmasq') |
            Where-Object { (& systemctl is-active $_ 2>$null) -eq 'active' } |
            Select-Object -First 1
        if (-not $resolver) { throw 'No supported active DNS caching service was found.' }
        & systemctl restart $resolver
        $method = "systemctl restart $resolver"
    }
    else {
        throw 'Neither resolvectl nor systemctl was found.'
    }
    if ($LASTEXITCODE -ne 0) { throw "DNS cache flush failed with exit code $LASTEXITCODE." }
}
else {
    throw "Unsupported platform '$($PSVersionTable.Platform)'."
}

[pscustomobject]@{ ComputerName = [Environment]::MachineName; Method = $method; Cleared = $true }
