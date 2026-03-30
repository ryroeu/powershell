# Enable TLS 1.2 in PowerShell
# NOTE: PowerShell 7+ uses TLS 1.2 (and 1.3) by default. This is only needed for Windows PowerShell 5.1.
if ($PSVersionTable.PSVersion.Major -lt 6) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}
