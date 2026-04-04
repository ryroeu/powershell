<#
.SYNOPSIS
    Retrieves logged on user.
#>

# Get LoggedOn User
# Define the server name
$Server = "YourRemoteServerName" # Replace with the actual server name or IP

try {
    # Query the Terminal Services sessions
    Get-CimInstance -ComputerName $Server -Namespace root\CIMV2\TerminalServices -ClassName Win32_TSSession | Select-Object -Property UserName, SessionId, State, ClientName, SessionType, ConnectTime, DisconnectTime, LogonTime
} catch {
    Write-Error "Failed to query sessions on $Server. Error: $($_.Exception.Message)"
    # Common issues include: WinRM not enabled/configured, firewall blocking, insufficient permissions, server offline.
}
