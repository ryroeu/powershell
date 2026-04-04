<#
.SYNOPSIS
    Compares 2 csv files.
#>

# --- Configuration ---
$PrimaryFilePath = Join-Path -Path $PSScriptRoot -ChildPath "File1.csv" # Assumes CSVs are in the same folder as the script
$LookupFilePath  = Join-Path -Path $PSScriptRoot -ChildPath "File2.csv"
$OutputFilePath  = Join-Path -Path $PSScriptRoot -ChildPath "File3.csv"
$KeyProperty     = "Name" # The column name to compare

# --- Input Validation ---
if (-not (Test-Path -Path $PrimaryFilePath -PathType Leaf)) {
    Write-Error "Primary input file not found: $PrimaryFilePath"
    exit 1 # Exit the script if the primary file is missing
}
if (-not (Test-Path -Path $LookupFilePath -PathType Leaf)) {
    Write-Error "Lookup input file not found: $LookupFilePath"
    exit 1 # Exit the script if the lookup file is missing
}

# --- Processing ---
try {
    # Import the lookup file and create a HashSet of the key property values for fast lookups
    # Using -UseCulture ensures case-insensitive comparison consistent with default PowerShell behavior if needed
    # Omit -UseCulture for default (case-insensitive) string comparison
    Write-Host "Loading lookup data from '$LookupFilePath'..."
    $lookupData = Import-Csv -Path $LookupFilePath
    # Handle potential empty lookup file
    if ($null -eq $lookupData) {
        $lookupKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        Write-Warning "Lookup file '$LookupFilePath' is empty or contains no data rows."
    } else {
         # Ensure the KeyProperty exists before trying to access it
        if ($lookupData[0].PSObject.Properties.Name -notcontains $KeyProperty) {
             Write-Error "Key property '$KeyProperty' not found in lookup file '$LookupFilePath'."
             exit 1
        }
        # Create HashSet for efficient checking. Using OrdinalIgnoreCase for case-insensitivity.
        $lookupKeys = [System.Collections.Generic.HashSet[string]]::new(
            ($lookupData.$KeyProperty), # Select only the specified property's values
            [System.StringComparer]::OrdinalIgnoreCase
        )
    }
    Write-Host "Loaded $($lookupKeys.Count) unique lookup keys based on '$KeyProperty'."

    # Import the primary file and filter it
    Write-Host "Loading and filtering primary data from '$PrimaryFilePath'..."
    $primaryData = Import-Csv -Path $PrimaryFilePath

    # Handle potential empty primary file
    if ($null -eq $primaryData) {
        Write-Warning "Primary file '$PrimaryFilePath' is empty or contains no data rows. Output file will be empty."
        $filteredData = @()
    } else {
        # Ensure the KeyProperty exists before trying to access it
        if ($primaryData[0].PSObject.Properties.Name -notcontains $KeyProperty) {
             Write-Error "Key property '$KeyProperty' not found in primary file '$PrimaryFilePath'."
             exit 1
        }
        # Filter primary data: keep rows where the KeyProperty value exists in the lookup HashSet
        $filteredData = $primaryData | Where-Object { $lookupKeys.Contains($_.$KeyProperty) }
    }

    # Export the filtered data, overwriting the output file
    Write-Host "Exporting $($filteredData.Count) filtered rows to '$OutputFilePath'..."
    $filteredData | Export-Csv -Path $OutputFilePath -NoTypeInformation -Encoding UTF8

    Write-Host "Script finished successfully."

} catch {
    Write-Error "An error occurred during processing: $($_.Exception.Message)"
    # You might want more detailed error logging or handling here
    exit 1
}
# --- End of Script ---