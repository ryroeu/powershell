<#
.SYNOPSIS
    Manages admt port check.
#>

function Get-PortQry {
    # Download PortQry utility
    Invoke-WebRequest -Uri https://www.microsoft.com/en-us/download/confirmation.aspx?id=17148 -OutFile ./PortQryV2.exe
    # Extract package
    Start-Process -Wait -FilePath ./PortQryv2.exe -ArgumentList '/q' -PassThru
}

function Get-ADMTPortStatus {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Target
    )
    # Test ports
    $ports = @(53, 88, 135, 137, 138, 389, 445, 3268)
    foreach ($port in $ports) {
        try {
            .\portqry -n $Target -p tcp -e $port -l C:\Temp\PortScan$port.txt -y
        } catch {
            Write-Error "Failed to scan port ${port}: $_"
        }
    }
}

function Show-FilteredPorts {
    # Create Directory
    if (-not (Test-Path C:\Temp)) {
        New-Item -Path C:\Temp -ItemType Directory
    }
    $Logs = (Get-ChildItem -Path C:\Temp\ -Filter "PortScan*").Name
    foreach ($Log in $Logs) {
        Get-Content -Path C:\Temp\$Log | Select-Object -First 23 | Select-Object -Last 1 
    }
}

# Ensure PortQry is installed
Get-PortQry

# Set target IP address
$Target = "8.8.8.8"

# Perform port scans
Get-ADMTPortStatus -Target $Target

# Show results
Show-FilteredPorts