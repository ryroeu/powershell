function Set-ARPRetryCount {
    $Servers = Import-Csv -Path C:\PowerShell\ServerList.csv
    foreach ($Server in $Servers) {
        InlineScript {
            New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "ArpRetryCount" -Value 0 -Force
        }
    }
}
Set-ARPRetryCount -AsJob -JobName "ArpRetryCount"