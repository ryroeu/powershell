<#
.SYNOPSIS
Connects to a VPN profile on Windows, macOS, or Linux.

.DESCRIPTION
This script detects the operating system at runtime and uses the safest built-in
backend available for that platform:

- Windows: `rasdial`
- macOS: `scutil --nc`
- Linux: `nmcli`

It also supports `openconnect` as an explicit backend when you need a direct
server connection instead of an OS-managed profile.

The script fixes the issues from the original per-OS variants by:

- using the correct macOS VPN tooling (`scutil --nc`) instead of PPPoE-only commands
- avoiding command-line password passing for `rasdial`, `scutil`, and `nmcli`
- prompting for credentials only when the selected backend can consume them safely

.PARAMETER ProfileName
The VPN profile or service name. When using `OpenConnect`, this can also be the
VPN server address if `ServerAddress` is not provided.

Compatibility aliases:
- `VpnProfileName`
- `VpnServiceName`
- `ConnectionName`

.PARAMETER UserName
Optional user name for the VPN connection. This is used by the `Scutil` and
`OpenConnect` backends. For `RasDial` and `Nmcli`, the connection profile or
the OS secret store should usually provide it.

.PARAMETER Backend
The backend to use. `Auto` selects the platform default:

- Windows -> `RasDial`
- macOS -> `Scutil`
- Linux -> `Nmcli`

.PARAMETER ServerAddress
Optional explicit VPN server address. Most useful with `OpenConnect`.

.PARAMETER Credential
Optional credential to use with `OpenConnect`. This parameter is intentionally
restricted to `OpenConnect` because the other supported backends would require
passing the password on the command line.

.PARAMETER UseOpenConnect
Compatibility switch for the legacy Linux script. Equivalent to `-Backend OpenConnect`.

.PARAMETER WaitSeconds
How long to wait for connection activation or status checks.

.PARAMETER PassThru
Returns a status object when the connection attempt finishes.

.EXAMPLE
pwsh ./MultiOS/VPNConnect.ps1 -ProfileName "My Work VPN"

Attempts to connect using the platform default backend.

.EXAMPLE
pwsh ./MultiOS/VPNConnect.ps1 -ProfileName "My Work VPN" -Backend Scutil -UserName "myuser"

Starts a macOS VPN service using `scutil --nc`.

.EXAMPLE
pwsh ./MultiOS/VPNConnect.ps1 -ProfileName "My Work VPN" -Backend Nmcli

Starts a Linux NetworkManager connection profile using `nmcli`.

.EXAMPLE
pwsh ./MultiOS/VPNConnect.ps1 -ProfileName "vpn.example.com" -Backend OpenConnect -UserName "myuser"

Prompts for credentials and starts an `openconnect` session.

.NOTES
Date: 2026-04-04
Requires:
- PowerShell 7+ for macOS/Linux
- Windows PowerShell 5.1 or PowerShell 7+ for Windows
- The platform-native backend (`rasdial`, `scutil`, `nmcli`, or `openconnect`)
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [Alias('VpnProfileName', 'VpnServiceName', 'ConnectionName')]
    [string]$ProfileName,

    [string]$UserName,

    [ValidateSet('Auto', 'RasDial', 'Scutil', 'Nmcli', 'OpenConnect')]
    [string]$Backend = 'Auto',

    [string]$ServerAddress,

    [System.Management.Automation.PSCredential]$Credential,

    [Alias('VpnClientPath')]
    [string]$ClientPath,

    [switch]$UseOpenConnect,

    [ValidateRange(1, 120)]
    [int]$WaitSeconds = 15,

    [switch]$PassThru
)

function Test-AutomaticBooleanVariable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $variable = Get-Variable -Name $Name -ErrorAction SilentlyContinue
    return ($null -ne $variable -and $variable.Value -eq $true)
}

function Get-DetectedPlatform {
    if (($env:OS -eq 'Windows_NT') -or (Test-AutomaticBooleanVariable -Name 'IsWindows') -or $PSVersionTable.Platform -eq 'Win32NT') {
        return 'Windows'
    }

    if (Test-AutomaticBooleanVariable -Name 'IsMacOS') {
        return 'MacOS'
    }

    if (Test-AutomaticBooleanVariable -Name 'IsLinux') {
        return 'Linux'
    }

    if ($PSVersionTable.OS -match 'Darwin|macOS') {
        return 'MacOS'
    }

    if ($PSVersionTable.OS -match 'Linux') {
        return 'Linux'
    }

    throw 'Unable to determine the current operating system.'
}

function Resolve-Backend {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$RequestedBackend,

        [Parameter(Mandatory = $true)]
        [bool]$OpenConnectRequested
    )

    if ($OpenConnectRequested) {
        if ($RequestedBackend -ne 'Auto' -and $RequestedBackend -ne 'OpenConnect') {
            throw 'UseOpenConnect cannot be combined with a different backend selection.'
        }

        return 'OpenConnect'
    }

    if ($RequestedBackend -ne 'Auto') {
        return $RequestedBackend
    }

    switch ($Platform) {
        'Windows' { return 'RasDial' }
        'MacOS'   { return 'Scutil' }
        'Linux'   { return 'Nmcli' }
        default   { throw "No default backend is defined for platform '$Platform'." }
    }
}

function Assert-BackendSupported {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$ResolvedBackend
    )

    switch ($ResolvedBackend) {
        'RasDial' {
            if ($Platform -ne 'Windows') {
                throw 'The RasDial backend is only supported on Windows.'
            }
        }
        'Scutil' {
            if ($Platform -ne 'MacOS') {
                throw 'The Scutil backend is only supported on macOS.'
            }
        }
        'Nmcli' {
            if ($Platform -ne 'Linux') {
                throw 'The Nmcli backend is only supported on Linux.'
            }
        }
    }
}

function Assert-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "Required command '$CommandName' was not found on this system."
    }

    return $command.Source
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    Write-Verbose ("Executing native command: {0} {1}" -f $CommandName, ($ArgumentList -join ' '))

    $output = & $CommandName @ArgumentList 2>&1
    $exitCode = $LASTEXITCODE

    [pscustomobject]@{
        Output   = @($output)
        ExitCode = $exitCode
    }
}

function Invoke-InteractiveNativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    Write-Verbose ("Executing interactive native command: {0} {1}" -f $CommandName, ($ArgumentList -join ' '))

    & $CommandName @ArgumentList
    $exitCode = $LASTEXITCODE

    [pscustomobject]@{
        ExitCode = $exitCode
    }
}

function New-VpnResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$Backend,

        [Parameter(Mandatory = $true)]
        [string]$ProfileName,

        [Parameter(Mandatory = $true)]
        [bool]$Connected,

        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    [pscustomobject]@{
        ProfileName = $ProfileName
        Platform    = $Platform
        Backend     = $Backend
        Connected   = $Connected
        Status      = $Status
        Timestamp   = Get-Date
    }
}

function Get-OpenConnectCredential {
    param(
        [string]$RequestedUserName,
        [System.Management.Automation.PSCredential]$SuppliedCredential
    )

    if ($null -ne $SuppliedCredential) {
        return $SuppliedCredential
    }

    if ($RequestedUserName) {
        return Get-Credential -UserName $RequestedUserName -Message 'Enter the VPN credentials for openconnect.'
    }

    return Get-Credential -Message 'Enter the VPN credentials for openconnect.'
}

function Connect-WithRasDial {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VpnProfileName
    )

    $null = Assert-NativeCommand -CommandName 'rasdial.exe'

    $profileLookup = Get-Command -Name 'Get-VpnConnection' -ErrorAction SilentlyContinue
    if ($profileLookup) {
        try {
            $null = Get-VpnConnection -Name $VpnProfileName -ErrorAction Stop
        }
        catch {
            throw "VPN profile '$VpnProfileName' was not found in the Windows VPN connection store."
        }
    }

    Write-Host "Connecting to Windows VPN profile '$VpnProfileName' using rasdial..."
    Write-Host 'Credentials are not passed on the command line. Use saved credentials in the VPN profile or the Windows prompt if it appears.'

    $connectResult = Invoke-InteractiveNativeCommand -CommandName 'rasdial.exe' -ArgumentList @($VpnProfileName)
    if ($connectResult.ExitCode -ne 0) {
        throw "rasdial failed with exit code $($connectResult.ExitCode)."
    }

    $statusResult = Invoke-NativeCommand -CommandName 'rasdial.exe' -ArgumentList @()
    $connected = $false

    if ($statusResult.ExitCode -eq 0) {
        foreach ($line in $statusResult.Output) {
            if ($line -match [regex]::Escape($VpnProfileName)) {
                $connected = $true
                break
            }
        }
    }

    if (-not $connected) {
        Write-Warning "rasdial reported success, but the active connection list did not clearly show '$VpnProfileName'."
    }

    return New-VpnResult -Platform 'Windows' -Backend 'RasDial' -ProfileName $VpnProfileName -Connected $connected -Status ($(if ($connected) { 'Connected' } else { 'Started' }))
}

function Get-ScutilServiceNames {
    $listResult = Invoke-NativeCommand -CommandName 'scutil' -ArgumentList @('--nc', 'list')
    if ($listResult.ExitCode -ne 0) {
        throw "Unable to enumerate macOS VPN services. scutil exited with code $($listResult.ExitCode)."
    }

    $serviceNames = @()
    foreach ($line in $listResult.Output) {
        if ($line -match '"([^"]+)"') {
            $serviceNames += $Matches[1]
        }
    }

    return $serviceNames
}

function Get-ScutilStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VpnProfileName
    )

    $statusResult = Invoke-NativeCommand -CommandName 'scutil' -ArgumentList @('--nc', 'status', $VpnProfileName)
    if ($statusResult.Output.Count -gt 0) {
        return [string]$statusResult.Output[0]
    }

    return 'Unknown'
}

function Connect-WithScutil {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VpnProfileName,

        [string]$RequestedUserName,

        [Parameter(Mandatory = $true)]
        [int]$StatusWaitSeconds
    )

    $null = Assert-NativeCommand -CommandName 'scutil'

    $serviceNames = Get-ScutilServiceNames
    if ($serviceNames -notcontains $VpnProfileName) {
        throw "VPN service '$VpnProfileName' was not found in macOS network connection services."
    }

    $arguments = @('--nc', 'start', $VpnProfileName)
    if ($RequestedUserName) {
        $arguments += @('--user', $RequestedUserName)
    }

    Write-Host "Connecting to macOS VPN service '$VpnProfileName' using scutil..."
    Write-Host 'Passwords are not passed on the command line. macOS may use Keychain or prompt through the system VPN stack.'

    $startResult = Invoke-InteractiveNativeCommand -CommandName 'scutil' -ArgumentList $arguments
    if ($startResult.ExitCode -ne 0) {
        throw "scutil exited with code $($startResult.ExitCode) while starting '$VpnProfileName'."
    }

    Start-Sleep -Seconds $StatusWaitSeconds
    $status = Get-ScutilStatus -VpnProfileName $VpnProfileName
    $connected = $status -match '^Connected\b'

    if (-not $connected) {
        Write-Warning "macOS reported VPN status '$status' for '$VpnProfileName'."
    }

    return New-VpnResult -Platform 'MacOS' -Backend 'Scutil' -ProfileName $VpnProfileName -Connected $connected -Status $status
}

function Connect-WithNmcli {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VpnProfileName,

        [Parameter(Mandatory = $true)]
        [int]$ActivationWaitSeconds
    )

    $null = Assert-NativeCommand -CommandName 'nmcli'

    $connectionList = Invoke-NativeCommand -CommandName 'nmcli' -ArgumentList @('-t', '--fields', 'NAME', 'connection', 'show')
    if ($connectionList.ExitCode -ne 0) {
        throw "Unable to enumerate NetworkManager connection profiles. nmcli exited with code $($connectionList.ExitCode)."
    }

    if ($connectionList.Output -notcontains $VpnProfileName) {
        throw "NetworkManager connection profile '$VpnProfileName' was not found."
    }

    Write-Host "Connecting to Linux VPN profile '$VpnProfileName' using nmcli..."
    Write-Host 'nmcli will ask for missing secrets interactively if the profile or secret agent does not already provide them.'

    $connectResult = Invoke-InteractiveNativeCommand -CommandName 'nmcli' -ArgumentList @('--ask', '--wait', $ActivationWaitSeconds.ToString(), 'connection', 'up', 'id', $VpnProfileName)
    if ($connectResult.ExitCode -ne 0) {
        throw "nmcli exited with code $($connectResult.ExitCode) while activating '$VpnProfileName'."
    }

    $activeResult = Invoke-NativeCommand -CommandName 'nmcli' -ArgumentList @('-t', '--fields', 'NAME', 'connection', 'show', '--active')
    $connected = $false

    if ($activeResult.ExitCode -eq 0 -and $activeResult.Output -contains $VpnProfileName) {
        $connected = $true
    }

    if (-not $connected) {
        Write-Warning "nmcli reported success, but '$VpnProfileName' was not listed as an active connection."
    }

    return New-VpnResult -Platform 'Linux' -Backend 'Nmcli' -ProfileName $VpnProfileName -Connected $connected -Status ($(if ($connected) { 'Connected' } else { 'Started' }))
}

function Connect-WithOpenConnect {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileOrServerName,

        [string]$RequestedUserName,

        [string]$RequestedServerAddress,

        [System.Management.Automation.PSCredential]$SuppliedCredential
    )

    $null = Assert-NativeCommand -CommandName 'openconnect'

    $targetHost = $RequestedServerAddress
    if (-not $targetHost) {
        $targetHost = $ProfileOrServerName
    }

    $openConnectCredential = Get-OpenConnectCredential -RequestedUserName $RequestedUserName -SuppliedCredential $SuppliedCredential
    $plainPassword = $openConnectCredential.GetNetworkCredential().Password

    try {
        Write-Host "Connecting to '$targetHost' using openconnect..."
        Write-Host 'openconnect usually runs in the foreground until you disconnect it.'

        $arguments = @("--user=$($openConnectCredential.UserName)", '--passwd-on-stdin', $targetHost)
        $plainPassword | & openconnect @arguments
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            throw "openconnect exited with code $exitCode."
        }

        Write-Host 'openconnect exited cleanly and the session has ended.'
        return New-VpnResult -Platform (Get-DetectedPlatform) -Backend 'OpenConnect' -ProfileName $ProfileOrServerName -Connected $false -Status 'SessionEnded'
    }
    finally {
        Clear-Variable plainPassword -ErrorAction SilentlyContinue
        Clear-Variable openConnectCredential -ErrorAction SilentlyContinue
    }
}

$platform = Get-DetectedPlatform
$resolvedBackend = Resolve-Backend -Platform $platform -RequestedBackend $Backend -OpenConnectRequested $UseOpenConnect.IsPresent
Assert-BackendSupported -Platform $platform -ResolvedBackend $resolvedBackend

if ($PSBoundParameters.ContainsKey('ClientPath')) {
    throw 'Generic external VPN client execution was intentionally removed from this multi-OS script because it previously relied on unsafe command-line password handling. Use the native platform backend or OpenConnect instead.'
}

if ($null -ne $Credential -and $resolvedBackend -ne 'OpenConnect') {
    throw 'The Credential parameter is only supported with the OpenConnect backend.'
}

if ($Credential -and $UserName) {
    Write-Warning 'The supplied UserName is ignored when Credential is also provided.'
}

if ($UserName -and $resolvedBackend -eq 'RasDial') {
    Write-Warning 'The RasDial backend does not accept credentials from this script to avoid exposing passwords. Use stored credentials in the VPN profile.'
}

if ($UserName -and $resolvedBackend -eq 'Nmcli') {
    Write-Warning 'The Nmcli backend relies on the saved NetworkManager profile or nmcli interactive secret prompts. UserName is not injected directly.'
}

Write-Host "Platform detected: $platform"
Write-Host "Selected backend: $resolvedBackend"

$targetDescription = switch ($resolvedBackend) {
    'OpenConnect' {
        if ($ServerAddress) {
            $ServerAddress
        } else {
            $ProfileName
        }
    }
    default {
        $ProfileName
    }
}

$result = $null

if ($PSCmdlet.ShouldProcess($targetDescription, "Connect VPN using $resolvedBackend")) {
    switch ($resolvedBackend) {
        'RasDial' {
            $result = Connect-WithRasDial -VpnProfileName $ProfileName
        }
        'Scutil' {
            $result = Connect-WithScutil -VpnProfileName $ProfileName -RequestedUserName $UserName -StatusWaitSeconds ([Math]::Max(1, [Math]::Min($WaitSeconds, 30)))
        }
        'Nmcli' {
            $result = Connect-WithNmcli -VpnProfileName $ProfileName -ActivationWaitSeconds $WaitSeconds
        }
        'OpenConnect' {
            $effectiveUserName = if ($Credential) { $Credential.UserName } else { $UserName }
            $result = Connect-WithOpenConnect -ProfileOrServerName $ProfileName -RequestedUserName $effectiveUserName -RequestedServerAddress $ServerAddress -SuppliedCredential $Credential
        }
        default {
            throw "Unhandled backend '$resolvedBackend'."
        }
    }
}

if ($PassThru -and $result) {
    $result
}
