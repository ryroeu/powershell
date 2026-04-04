<#
.SYNOPSIS
Displays IP address information for active network adapters using .NET classes.

.DESCRIPTION
This script retrieves IPv4 and IPv6 address information using the cross-platform
System.Net.NetworkInformation.NetworkInterface .NET class, which is reliably
available in PowerShell 7+ across platforms. It displays the Interface Name,
IP Address, and Address Family for operational, non-loopback interfaces.
It works on Windows, macOS, and Linux where PowerShell 7+ is installed.

.NOTES
Date: 2025-04-04
Compatibility: PowerShell 7.0+ (Windows, macOS, Linux)
#>

Clear-Host
Write-Host "--- IP Address Information (.NET Method) ---"

try {
    # Get all network interfaces using .NET
    $interfaces = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()

    if ($interfaces) {
        $ipOutput = foreach ($interface in $interfaces) {
            # Filter for interfaces that are 'Up' and not Loopback
            if ($interface.OperationalStatus -eq 'Up' -and $interface.NetworkInterfaceType -ne 'Loopback') {
                # Get IP properties for the interface
                $ipProperties = $interface.GetIPProperties()

                # Process each unicast address associated with the interface
                foreach ($addressInfo in $ipProperties.UnicastAddresses) {
                    # Create a custom object to hold the desired information
                    # ($addressInfo.Address contains the IPAddress object)
                    [PSCustomObject]@{
                        InterfaceName = $interface.Name
                        AddressFamily = $addressInfo.Address.AddressFamily # Displays InterNetwork (IPv4) or InterNetworkV6 (IPv6)
                        IPAddress     = $addressInfo.Address.ToString()
                        # You could add more properties here if needed, e.g.:
                        # Description   = $interface.Description
                        # SubnetMask    = $addressInfo.IPv4Mask # Note: Check applicability for IPv6
                    }
                }
            }
        }

        if ($ipOutput) {
            # Format the collected information as a table
            $ipOutput | Format-Table -AutoSize
        } else {
            Write-Warning "No active, non-loopback IP addresses found."
        }

    } else {
        Write-Warning "Could not retrieve any network interface information."
    }

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
}

Write-Host "" # Add a blank line for spacing before the prompt

# Pause script execution until the user presses Enter
Read-Host -Prompt "Press Enter to exit"