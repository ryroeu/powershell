#Requires -Version 7.6
#Requires -Modules Microsoft.PowerShell.ThreadJob

<#
.SYNOPSIS
    Manages network utility.
#>

# === How to Use ===
# 1. Save the script (e.g., as NetUtils.ps1)
# 2. Open PowerShell
# 3. Dot-source the script to load the functions: . .\NetUtils.ps1
#
# 4. Start the listener (Server):
#    Get-Port -Verbose                            # Listens on localhost:8989 with verbose output
#    Get-Port -Port 9999 -IPAddress 0.0.0.0       # Listens on port 9999 on ALL network interfaces (use 0.0.0.0 for "Any")
#    # Press Ctrl+C in the listener's window to stop it gracefully.
#
# 5. Open *another* PowerShell window
# 6. Dot-source the script again: . .\NetUtils.ps1
#
# 7. Send messages (Client):
#    Send-Msg -Message "Hello from client 1" -Verbose
#    Send-Msg -Message "Another message" -Port 8989 -Server localhost
#    Send-Msg -Message "Test to other IP" -Server 192.168.0.100 -Port 9999 # (If listener is on that IP/port)
#    Send-Msg # Sends the default [char]4 message

# --- Example Auto-Run (Optional - uncomment to run listener immediately) ---
# Write-Host "Starting listener immediately..." -ForegroundColor Magenta
# Get-Port -Verbose
# -------------------------------------------------------------------------
# This script provides a simple TCP server and client for testing and communication.
# The server listens for incoming connections and the client can send messages.
# It uses PowerShell jobs to handle multiple clients concurrently.
# The server can be configured to listen on a specific port and IP address.
# The client can send messages to the server and handle responses.
# The script includes error handling, logging, and resource management.
# It is designed to be run in PowerShell Core (pwsh) for cross-platform compatibility.
# It is recommended to run the script with administrative privileges for full functionality.
function Get-Port {
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,65535)]
        [int]$Port = 8989,

        [Parameter(Mandatory=$false)]
        [System.Net.IPAddress]$IPAddress = [System.Net.IPAddress]::Loopback # Default to localhost for safety
    )

    $endpoint = New-Object System.Net.IPEndPoint ($IPAddress, $Port)
    $listener = New-Object System.Net.Sockets.TcpListener $endpoint
    $jobs = [System.Collections.Generic.List[System.Management.Automation.Job]]::new() # To keep track of jobs

    try {
        $listener.Start()
        Write-Verbose "Listener started on $IPAddress`: `$Port. Waiting for connections..."
        Write-Host "Listener active on $IPAddress`: `$Port. Press Ctrl+C to stop." -ForegroundColor Green

        # Main loop to accept clients
        while ($true) { # Loop indefinitely until Ctrl+C
            try {
                # Check for completed jobs and remove them to clean up
                $jobs | Where-Object { $_.State -in 'Completed', 'Failed', 'Stopped' } | ForEach-Object {
                    Write-Verbose "Cleaning up finished job $($_.Id) ($($_.State))"
                    Receive-Job $_ # Optional: Get any output from the job
                    Remove-Job $_
                    $jobs.Remove($_)
                }

                # Check for pending connections (non-blocking check)
                if ($listener.Pending()) {
                    Write-Verbose "Incoming connection detected..."
                    $client = $listener.AcceptTcpClient() # Accept the connection
                    $clientIP = $client.Client.RemoteEndPoint.ToString()
                    Write-Verbose "Client connected from $clientIP"

                    # A thread job is required because a process job serializes TcpClient and loses its live socket.
                    $job = Start-ThreadJob -Name "ClientHandler_$clientIP" -ScriptBlock {
                        $clientInstance = $using:client
                        $clientIPAddr = $using:clientIP

                        # Set basic timeouts (in milliseconds)
                        $clientInstance.SendTimeout = 5000
                        $clientInstance.ReceiveTimeout = 30000 # 30 seconds

                        $stream = $null
                        $reader = $null
                        $clientDisconnected = $false

                        try {
                            $stream = $clientInstance.GetStream()
                            $reader = New-Object System.IO.StreamReader($stream)
                            $receivedAnything = $false

                            # Inner loop to read from this specific client
                            do {
                                $line = $null # Reset line for each read attempt
                                try {
                                    # ReadLine() will block until a line is received, timeout occurs, or client disconnects
                                    $line = $reader.ReadLine()
                                } catch [System.IO.IOException] {
                                     # Catch timeout or forcible close errors
                                     Write-Warning "($clientIPAddr) IO Error reading from client (Timeout or closed connection): $($_.Exception.Message)"
                                     $line = $null # Ensure loop condition might exit
                                     $clientDisconnected = $true
                                } catch {
                                     Write-Warning "($clientIPAddr) Unexpected Error reading from client: $($_.Exception.Message)"
                                     $line = $null
                                     $clientDisconnected = $true
                                }

                                if ($null -ne $line) {
                                    $receivedAnything = $true
                                    # Output the line to the job stream (can be retrieved with Receive-Job)
                                    Write-Output "($clientIPAddr) Received: $line"
                                    # Also write to host directly from job for immediate feedback (optional)
                                    Write-Host "($clientIPAddr): $line" -ForegroundColor Cyan

                                    # Check for specific termination signal from client (optional)
                                    if ($line -eq ([char]4)) {
                                        Write-Host "($clientIPAddr): Client sent termination signal." -ForegroundColor Yellow
                                        break # Exit inner read loop for this client
                                    }
                                } elseif ($clientDisconnected) {
                                    break # Exit loop if an error indicated disconnection
                                }

                            } while ($null -ne $line -and $clientInstance.Connected) # Continue if line has value and client still seems connected

                            if (-not $receivedAnything -and -not $clientDisconnected) {
                                Write-Host "($clientIPAddr): Client connected but sent no data or timed out." -ForegroundColor Yellow
                            }

                        } catch {
                            Write-Warning "($clientIPAddr) Error processing client: $($_.Exception.Message)"
                        } finally {
                            # Cleanup resources for this client connection *within the job*
                            if ($null -ne $reader) { $reader.Dispose() }
                            if ($null -ne $stream) { $stream.Dispose() }
                            if ($null -ne $clientInstance) { $clientInstance.Dispose() }
                            Write-Host "($clientIPAddr): Client disconnected and resources cleaned up." -ForegroundColor Gray
                        }
                    }

                    $jobs.Add($job) # Add the new job to our tracking list
                    Write-Verbose "Started job $($job.Id) to handle client $clientIP"

                } else {
                    # No pending connection, wait a short time to avoid pegging CPU
                    Start-Sleep -Milliseconds 100
                }

            } catch [System.Net.Sockets.SocketException] {
                 # Handle errors during AcceptTcpClient (less common if Start() succeeded)
                 Write-Error "Socket Error accepting client: $($_.Exception.Message)"
                 # Potentially break the loop or log and continue depending on severity
                 Start-Sleep -Seconds 1
            } catch {
                 Write-Error "Unexpected Error in accept loop: $($_.Exception.Message)"
                 # Potentially break the loop or log and continue
                 Start-Sleep -Seconds 1
            }
        } # End while ($true)

    } catch [System.Net.Sockets.SocketException] {
        Write-Error "Failed to start listener on $IPAddress`: `$Port. Port may be in use or permission denied. $($_.Exception.Message)"
    } catch {
        Write-Error "An unexpected error occurred: $($_.Exception.Message)"
    } finally {
        # This block executes when the loop exits (e.g., Ctrl+C)
        Write-Host "`nStopping listener..." -ForegroundColor Yellow
        if ($null -ne $listener -and $null -ne $listener.Server -and $listener.Server.IsBound) {
             $listener.Stop()
             Write-Verbose "Listener stopped."
        }
        # Stop and remove any running jobs
        if ($jobs.Count -gt 0) {
            Write-Host "Stopping and cleaning up $($jobs.Count) active client jobs..." -ForegroundColor Yellow
            $jobs | ForEach-Object {
                 Stop-Job $_ -PassThru | Remove-Job -Force
            }
        }
        Write-Host "Server shut down complete." -ForegroundColor Green
    }
}

function Send-Msg {
    [CmdletBinding(SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Message = "$([char]4)", # Default to End-of-Transmission

        [Parameter(Mandatory=$false)]
        [ValidateRange(1,65535)]
        [int]$Port = 8989,

        [Parameter(Mandatory=$false)]
        [string]$Server = "localhost" # Use string for flexibility (hostname or IP)
    )

    $client = $null
    $stream = $null
    $writer = $null

    try {
        Write-Verbose "Attempting to connect to $Server`:`$Port..."
        $client = New-Object System.Net.Sockets.TcpClient
        # Add a connection timeout (e.g., 5 seconds)
        $connectTask = $client.ConnectAsync($Server, $Port)
        if ($connectTask.Wait(5000)) { # Wait for 5 seconds
             Write-Verbose "Connection successful."
             $stream = $client.GetStream()
             # Use UTF8 encoding for broader compatibility
             $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::UTF8)
             # Use WriteLine to ensure message is sent immediately with newline (often expected by line readers)
             # If the original receiver *strictly* needs no newline, use $writer.Write($Message)
             $writer.WriteLine($Message)
             $writer.Flush() # Ensure data is sent
             Write-Verbose "Message sent: $Message"
        } else {
            throw "Connection timed out connecting to $Server`:`$Port."
        }

    } catch [System.Net.Sockets.SocketException] {
        Write-Error "Cannot connect to $Server`:`$Port. Server may not be running or firewall blocking. $($_.Exception.Message)"
    } catch {
        Write-Error "An error occurred during send: $($_.Exception.Message)"
    } finally {
        # Dispose in reverse order of creation
        if ($null -ne $writer) { $writer.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
        if ($null -ne $client) { $client.Dispose() }
        Write-Verbose "Client resources disposed."
    }
}
