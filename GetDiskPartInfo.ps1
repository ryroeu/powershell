<#
.SYNOPSIS
    Retrieves disk part information.
#>

Function Get-DiskInfoAdvanced {
    [CmdletBinding()]
    Param()

    Write-Verbose "Gathering disk information using native PowerShell cmdlets."

    # Get all physical disk objects
    # Use -ErrorAction SilentlyContinue in case CIM session fails (less common issue)
    $physicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue

    if (-not $physicalDisks) {
        Write-Warning "Could not retrieve physical disk information. Ensure the Storage module is available and functional."
        return # Return an empty collection or handle as needed
    }

    $diskInfoCollection = foreach ($physicalDisk in $physicalDisks) {
        Write-Verbose "Processing Disk $($physicalDisk.DeviceID) - Model: $($physicalDisk.Model)"

        # Initialize drive letter variable
        $driveLetters = $null

        try {
            # Get partitions associated with this physical disk
            # Need to get the associated MSFT_Disk object first to reliably link Partitions
            $disk = Get-Disk -Number $physicalDisk.DeviceID -ErrorAction Stop

            # Get partitions for the disk
            $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue

            if ($partitions) {
                # Collect drive letters from all partitions on this disk
                # Filter out partitions that don't have an assigned drive letter
                $letters = $partitions | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
                if ($letters) {
                    # Join multiple letters with a comma, handle single letter case
                    $driveLetters = $letters -join ','
                } else {
                    $driveLetters = "[No Letter]" # Indicate no drive letter assigned
                }
            } else {
                 Write-Verbose "No partitions found for Disk $($disk.Number)."
                 $driveLetters = "[No Partitions]"
            }
        } catch {
            Write-Warning "Error processing partitions/volumes for Disk $($physicalDisk.DeviceID): $($_.Exception.Message)"
            $driveLetters = "[Error]" # Indicate an error occurred retrieving letters
        }

        # Construct the output object
        [PSCustomObject]@{
            DiskNum     = $physicalDisk.DeviceID # Or $disk.Number - usually the same
            Model       = $physicalDisk.Model.Trim() # Model from PhysicalDisk
            Type        = $physicalDisk.MediaType # Type (e.g., SSD, HDD, NVMe) from PhysicalDisk
            DiskSize    = $physicalDisk.Size # Size in bytes (usually UInt64)
            DriveLetter = $driveLetters # Collected drive letter(s) or status
            # Additional potentially useful properties:
            # SerialNumber = $physicalDisk.SerialNumber
            # HealthStatus = $physicalDisk.HealthStatus
            # BusType      = $physicalDisk.BusType
        }
    }

    # Output the collected information
    return $diskInfoCollection
}

# --- Example Usage ---

# Get the data
$diskData = Get-DiskInfoAdvanced -Verbose # Use -Verbose for detailed progress

# Display in a table (like the original script)
$diskData | Format-Table

# Example filtering (like the original commented-out section)
# Note: The 'Type' property now represents MediaType (SSD, HDD etc.)
#       The 'DiskSize' is in bytes.

# $targetType = "SSD"
# $minSizeGB = 100
# $maxSizeGB = 500
# $minSizeBytes = $minSizeGB * 1GB
# $maxSizeBytes = $maxSizeGB * 1GB

# Write-Host "`nFiltering Example: $($targetType) drives between $($minSizeGB)GB and $($maxSizeGB)GB"
# Get-DiskInfoAdvanced | Where-Object { $_.Type –eq $targetType –and $_.DiskSize -lt $maxSizeBytes -and $_.DiskSize –gt $minSizeBytes } | Format-Table