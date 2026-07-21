<#
.SYNOPSIS
Registers PowerShell Core 7+ WinRM session configuration endpoints.

.DESCRIPTION
This script configures the necessary WinRM plugin and session configurations
to allow remote connections to a specific PowerShell Core 7+ installation.
It requires administrative privileges to modify WinRM settings and registry keys.

It registers two endpoints:
1. Version-specific (e.g., PowerShell.7.4.1)
2. Major-version specific (e.g., PowerShell.7)

.PARAMETER PowerShellHome
Specifies the installation directory (PSHOME) of the PowerShell Core version
to configure. If not specified, the PSHOME of the currently running PowerShell
instance is used.

.PARAMETER Force
Overwrites existing session configurations and plugin registrations if they exist.

.EXAMPLE
.\Enable-PSCoreRemoting.ps1
# Configures WinRM for the PowerShell Core instance running the script.

.EXAMPLE
.\Enable-PSCoreRemoting.ps1 -PowerShellHome "C:\Program Files\PowerShell\7"
# Configures WinRM for the PowerShell Core instance located in the specified directory.

.EXAMPLE
.\Enable-PSCoreRemoting.ps1 -Force
# Configures WinRM for the current PowerShell Core instance, overwriting existing configurations.

.NOTES
- Must be run as Administrator.
- Restarts the WinRM service upon completion.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (
    [Parameter()]
    [string] $PowerShellHome,

    [Parameter()]
    [switch] $Force
)

Set-StrictMode -Version Latest

#region Pre-checks and Setup
# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Error "Administrator rights are required to register WinRM plugins and session configurations. Please re-run PowerShell as Administrator." -ErrorAction Stop
}

# Determine target PowerShell Home and Version
$TargetPsHome = $null
$TargetPsVersion = $null
$TargetPsVersionMajorMinor = $null

if (-not [string]::IsNullOrEmpty($PowerShellHome)) {
    # Validate provided PowerShellHome
    $ResolvedPowerShellHome = Resolve-Path -Path $PowerShellHome -ErrorAction SilentlyContinue
    if (-not $ResolvedPowerShellHome) {
        Write-Error "Specified PowerShellHome path '$PowerShellHome' not found." -ErrorAction Stop
    }
    $TargetPsHome = $ResolvedPowerShellHome.Path
    $pwshExePath = Join-Path $TargetPsHome "pwsh.exe"
    $pluginDllPath = Join-Path $TargetPsHome "pwrshplugin.dll"

    if (-not (Test-Path $pwshExePath -PathType Leaf)) {
         Write-Error "Could not find 'pwsh.exe' in the specified PowerShellHome: '$TargetPsHome'." -ErrorAction Stop
    }
     if (-not (Test-Path $pluginDllPath -PathType Leaf)) {
         Write-Error "Could not find 'pwrshplugin.dll' in the specified PowerShellHome: '$TargetPsHome'." -ErrorAction Stop
    }

    Write-Verbose "Using specified PowerShellHome: $TargetPsHome"
    try {
        # Get version by invoking the target pwsh
        $TargetPsVersionString = & $pwshExePath -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        $TargetPsVersion = [version]$TargetPsVersionString
        Write-Verbose "Determined Target PS Version: $($TargetPsVersion.ToString())"
    }
    catch {
        Write-Error "Failed to determine PowerShell version from '$pwshExePath'. Error: $($_.Exception.Message)" -ErrorAction Stop
    }
}
else {
    # Use the current PowerShell instance if PSHome parameter was not specified
    if ($PSVersionTable.PSVersion.Major -lt 7) {
         Write-Error "This script requires PowerShell 7+ to run, or you must specify the -PowerShellHome parameter pointing to a PowerShell 7+ installation." -ErrorAction Stop
    }
    $TargetPsHome = $PSHOME
    $TargetPsVersion = $PSVersionTable.PSVersion
    Write-Verbose "Using current PowerShell instance's PSHome: $TargetPsHome"
    Write-Verbose "Using current PowerShell instance's Version: $($TargetPsVersion.ToString())"
}

# Ensure we have a valid version object
if ($null -eq $TargetPsVersion) {
     Write-Error "Could not determine the target PowerShell version." -ErrorAction Stop
}

# Extract Major.Minor version (e.g., "7.4") required for the plugin config XML
$TargetPsVersionMajorMinor = "$($TargetPsVersion.Major).$($TargetPsVersion.Minor)"
# Full version string (e.g., "7.4.1") for endpoint name and path
$TargetPsVersionFull = $TargetPsVersion.ToString()

# Construct the base path for the plugin within System32
# Example: C:\Windows\System32\PowerShell\7.4.1
$pluginVersionedBasePath = Join-Path $env:SystemRoot "System32\PowerShell\$TargetPsVersionFull"
# Example: pwrshplugin.dll path C:\Windows\System32\PowerShell\7.4.1\pwrshplugin.dll
$pluginDllSystemPath = Join-Path $pluginVersionedBasePath 'pwrshplugin.dll'
# Example: Config file path C:\Windows\System32\PowerShell\7.4.1\RemotePowerShellConfig.txt
$pluginConfigFileSystemPath = Join-Path $pluginVersionedBasePath 'RemotePowerShellConfig.txt'

# Source DLL path from the target PS installation
$sourcePluginDll = Join-Path $TargetPsHome 'pwrshplugin.dll'
if (-not (Test-Path $sourcePluginDll -PathType Leaf)) {
    Write-Error "Required plugin file '$sourcePluginDll' not found in target PowerShell home." -ErrorAction Stop
}

#endregion

#region Helper Functions

function Register-WinRmPluginInternal {
    param (
        [parameter(Mandatory)]
        [string]$PluginDllSystemPath,

        [parameter(Mandatory)]
        [string]$PluginEndpointName,

        [parameter(Mandatory)]
        [string]$PluginPsVersionMajorMinor # Expects "Major.Minor" format (e.g., "7.4")
    )

    $regKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Plugin\$PluginEndpointName"

    # Determine architecture - Use OS architecture for robustness, though process usually matches for PWSH 7+
    $pluginArchitecture = if ((Get-CimInstance Win32_OperatingSystem).OSArchitecture -eq '64-bit') { '64' } else { '32' }
    Write-Verbose "Determined Plugin Architecture: $pluginArchitecture"

    # XML configuration template for the WinRM plugin
    # Placeholder {0}: PluginEndpointName (e.g., PowerShell.7.4.1)
    # Placeholder {1}: PluginDllSystemPath (e.g., C:\WINDOWS\System32\PowerShell\7.4.1\pwrshplugin.dll)
    # Placeholder {2}: PluginArchitecture (e.g., 64)
    # Placeholder {3}: PluginPsVersionMajorMinor (e.g., 7.4) - *** CRITICAL FIX FOR PS7+ ***
    $regKeyValueFormatString = @'
<PlugInConfiguration xmlns="http://schemas.microsoft.com/wbem/wsman/1/config/PluginConfiguration" Name="{0}" Filename="{1}"
 SDKVersion="2" XmlRenderingType="text" Enabled="True" UseSharedProcess="false" ProcessIdleTimeoutSec="0" RunAsUser="" RunAsPassword=""
 Architecture="{2}" OutputBufferingMode="Block" AutoRestart="false">
 <InitializationParameters>
  <Param Name="PSVersion" Value="{3}"/>
 </InitializationParameters>
 <Resources>
  <Resource ResourceUri="http://schemas.microsoft.com/powershell/{0}" SupportsOptions="true" ExactMatch="true">
   <Security Uri="http://schemas.microsoft.com/powershell/{0}" ExactMatch="true" Sddl="O:NSG:BAD:P(A;;GA;;;BA)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"/>
   <Capability Type="Shell"/>
  </Resource>
 </Resources>
 <Quotas IdleTimeoutms="7200000" MaxConcurrentUsers="5" MaxProcessesPerShell="15" MaxMemoryPerShellMB="1024" MaxShellsPerUser="25" MaxConcurrentCommandsPerShell="1000" MaxShells="25" MaxIdleTimeoutms="43200000"/>
</PlugInConfiguration>
'@
    $valueString = $regKeyValueFormatString -f $PluginEndpointName, $PluginDllSystemPath, $pluginArchitecture, $PluginPsVersionMajorMinor

    Write-Verbose "Creating/Updating registry key: $regKey"
    try {
        # Ensure the parent path exists before creating the item
        $parentPath = Split-Path -Path $regKey -Parent
        if (-not (Test-Path $parentPath)) {
             New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        if (-not (Test-Path $regKey)) {
            New-Item $regKey -Force -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -Path $regKey -Name ConfigXML -Value $valueString -PropertyType String -Force -ErrorAction Stop | Out-Null
        Write-Verbose "Successfully wrote ConfigXML to registry for $PluginEndpointName."
    }
    catch {
        Write-Error "Failed to write registry configuration for '$PluginEndpointName'. Error: $($_.Exception.Message)" -ErrorAction Stop # Changed to Stop
    }
}

function New-PluginConfigFileInternal {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory)]
        [string]$TargetPluginConfigFile, # e.g., C:\Windows\System32\PowerShell\7.4.1\RemotePowerShellConfig.txt

        [parameter(Mandatory)]
        [string]$ResolvedTargetPsHomeDir # e.g., C:\Program Files\PowerShell\7
    )

    if ($PSCmdlet.ShouldProcess($TargetPluginConfigFile, "Create WinRM Plugin Configuration File")) {
        $configContent = @"
PSHOMEDIR=$ResolvedTargetPsHomeDir
CORECLRDIR=$ResolvedTargetPsHomeDir
"@
        try {
            Set-Content -Path $TargetPluginConfigFile -Value $configContent -Force -ErrorAction Stop
            Write-Verbose "Created/Updated Plugin Config File: $TargetPluginConfigFile"
        }
        catch {
            Write-Error "Failed to create plugin configuration file '$TargetPluginConfigFile'. Error: $($_.Exception.Message)" -ErrorAction Stop # Changed to Stop
        }
    }
}

function Install-PluginAndEndpoint {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [parameter(Mandatory)]
        [string]$PluginDllSystemPath, # Where the DLL should be copied TO in System32

        [parameter(Mandatory)]
        [string]$SourcePluginDllPath, # Where the DLL is copied FROM in PSHome

        [parameter(Mandatory)]
        [string]$PluginConfigFileSystemPath, # Where the config TXT file should be created in System32

        [parameter(Mandatory)]
        [string]$ResolvedTargetPsHome, # The actual PSHOME path used for the config TXT file content

        [parameter(Mandatory)]
        [string]$PluginEndpointName, # The name for the PSSessionConfiguration and Registry Key

        [parameter(Mandatory)]
        [string]$PluginPsVersionMajorMinor, # The "Major.Minor" version string for the XML config

        [parameter(Mandatory)]
        [string]$PluginVersionedBasePath, # The directory in System32 (e.g., C:\Win\Sys32\PS\7.4.1)

        [parameter(Mandatory)]
        [switch]$ForceWrite
    )

    Write-Verbose "Processing endpoint: $PluginEndpointName"

    # Check existing configuration only if not forcing
    $existingEndpoint = Get-PSSessionConfiguration -Name $PluginEndpointName -ErrorAction SilentlyContinue
    if ($existingEndpoint -and (-not $ForceWrite)) {
        Write-Warning "Session configuration '$PluginEndpointName' already exists. Use -Force to overwrite."
        return $false # Indicate skipped/failed
    }

    # Perform the operation if ShouldProcess permits
    if ($PSCmdlet.ShouldProcess($PluginEndpointName, "Register WinRM Plugin and Session Configuration")) {

        # 1. Ensure target directory exists in System32
        if (-not (Test-Path $PluginVersionedBasePath -PathType Container)) {
            Write-Verbose "Creating plugin directory: $PluginVersionedBasePath"
            try {
                New-Item -Path $PluginVersionedBasePath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            catch {
                 Write-Error "Failed to create plugin directory '$PluginVersionedBasePath'. Error: $($_.Exception.Message)" -ErrorAction Stop
            }
        }

        # 2. Copy the plugin DLL
        Write-Verbose "Copying '$SourcePluginDllPath' to '$PluginDllSystemPath'"
        try {
            Copy-Item -Path $SourcePluginDllPath -Destination $PluginDllSystemPath -Force -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to copy plugin DLL to '$PluginDllSystemPath'. Error: $($_.Exception.Message)" -ErrorAction Stop
        }

        # 3. Create the configuration text file
        New-PluginConfigFileInternal -TargetPluginConfigFile $PluginConfigFileSystemPath -ResolvedTargetPsHomeDir $ResolvedTargetPsHome -Verbose:$VerbosePreference

        # 4. Register the plugin in the registry (this creates/updates the registry keys)
        Register-WinRmPluginInternal -PluginDllSystemPath $PluginDllSystemPath `
                                     -PluginEndpointName $PluginEndpointName `
                                     -PluginPsVersionMajorMinor $PluginPsVersionMajorMinor `
                                     -Verbose:$VerbosePreference

        # 5. Register the PSSessionConfiguration (makes it visible to Get-PSSessionConfiguration, etc.)
        #    This reads the registry config we just created. Use -Force if specified.
        Write-Verbose "Registering PSSessionConfiguration: $PluginEndpointName"
        $regParams = @{
            Name = $PluginEndpointName
            Force = $ForceWrite
            ErrorAction = 'Stop' # Changed to Stop
        }
        try {
             Register-PSSessionConfiguration @regParams -Verbose:$false # Suppress verbose from this cmdlet itself
             Write-Information "Successfully registered PSSessionConfiguration '$PluginEndpointName'." # Use Write-Information
        }
        catch {
            Write-Error "Failed to register PSSessionConfiguration '$PluginEndpointName'. This might happen if the registry configuration is incorrect or WinRM is malfunctioning. Error: $($_.Exception.Message)"
            # Don't stop the whole script here, maybe the other endpoint will work. But return failure.
             return $false
        }

        # 6. Validation
        $validationEndpoint = Get-PSSessionConfiguration -Name $PluginEndpointName -ErrorAction SilentlyContinue
        if ($null -eq $validationEndpoint) {
             Write-Warning "Validation failed: PSSessionConfiguration '$PluginEndpointName' not found after registration attempt."
             return $false
        } else {
             Write-Verbose "Validation successful: Found PSSessionConfiguration '$PluginEndpointName'."
             return $true # Indicate success
        }
    } # End ShouldProcess
    else {
         Write-Warning "Skipped configuration for '$PluginEndpointName' due to -WhatIf."
         return $false # Indicate skipped
    }
}

#endregion

#region Main Execution

# Register Version Specific Endpoint (e.g., PowerShell.7.4.1)
$endpointNameSpecific = "PowerShell.$TargetPsVersionFull"
Write-Host "`nProcessing Version Specific Endpoint: $endpointNameSpecific" -ForegroundColor Cyan
$successSpecific = Install-PluginAndEndpoint -PluginDllSystemPath $pluginDllSystemPath `
                                             -SourcePluginDllPath $sourcePluginDll `
                                             -PluginConfigFileSystemPath $pluginConfigFileSystemPath `
                                             -ResolvedTargetPsHome $TargetPsHome `
                                             -PluginEndpointName $endpointNameSpecific `
                                             -PluginPsVersionMajorMinor $TargetPsVersionMajorMinor `
                                             -PluginVersionedBasePath $pluginVersionedBasePath `
                                             -ForceWrite $Force `
                                             -Verbose:$VerbosePreference `
                                             -WhatIf:$WhatIfPreference

# Register Major Version Endpoint (e.g., PowerShell.7)
$endpointNameMajor = "PowerShell.$($TargetPsVersion.Major)"
Write-Host "`nProcessing Major Version Endpoint: $endpointNameMajor" -ForegroundColor Cyan
$successMajor = Install-PluginAndEndpoint -PluginDllSystemPath $pluginDllSystemPath `
                                          -SourcePluginDllPath $sourcePluginDll `
                                          -PluginConfigFileSystemPath $pluginConfigFileSystemPath `
                                          -ResolvedTargetPsHome $TargetPsHome `
                                          -PluginEndpointName $endpointNameMajor `
                                          -PluginPsVersionMajorMinor $TargetPsVersionMajorMinor `
                                          -PluginVersionedBasePath $pluginVersionedBasePath `
                                          -ForceWrite $Force `
                                          -Verbose:$VerbosePreference `
                                          -WhatIf:$WhatIfPreference

#endregion

#region Final Steps

# Restart WinRM only if changes were made and not running in -WhatIf mode
if (($successSpecific -or $successMajor) -and (-not $WhatIfPreference)) {
    Write-Information "`nRestarting WinRM service to apply changes..."
    try {
        Restart-Service -Name WinRM -Force -ErrorAction Stop
        Write-Information "WinRM service restarted successfully."
    }
    catch {
         Write-Error "Failed to restart the WinRM service. You may need to restart it manually ('Restart-Service WinRM'). Error: $($_.Exception.Message)"
    }
}
elseif (-not ($successSpecific -or $successMajor)) {
     Write-Warning "No changes were successfully applied. WinRM service was not restarted."
}

Write-Host "`nScript finished." -ForegroundColor Green

#endregion
