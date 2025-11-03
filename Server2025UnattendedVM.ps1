<#
.SYNOPSIS
Generate Autounattend.xml for Windows Server 2022/2025 and optionally craft an ISO (requires oscdimg.exe).
.DESCRIPTION
Replaces Server2022UnattendedVM.ps1. Produces an answer file with:
- UEFI/GPT disk layout (EFI/MSR/Windows/Recovery)
- Locale, timezone, product key placeholder
- Local Administrator password (optional) & autologon (optional)
- WinRM enablement, OpenSSH.Server capability, .NET 3.5 on-demand
- Disables IE ESC and Server Manager at logon (for lab use)
.PARAMETER OutputDir
Directory to write Autounattend.xml (and ISO if built).
.PARAMETER Edition
Server edition label used by setup (e.g., "Windows Server 2025 Standard (Desktop Experience)"). For 2022 keep the appropriate label.
.PARAMETER TimeZone
Windows time zone ID (default "Romance Standard Time").
.PARAMETER ProductKey
Optional KMS/GVLK or retail key. Leave empty to skip.
.PARAMETER AdministratorPassword
Optional local Administrator password. If omitted, setup will prompt on first logon.
.PARAMETER BuildISO
If supplied, will create <Edition>-Unattended.iso using oscdimg when available.
.PARAMETER SourceISO
Path to original Microsoft ISO when using -BuildISO.
.EXAMPLE
.\New-ServerUnattended.ps1 -OutputDir C:\Temp -Edition "Windows Server 2025 Standard (Desktop Experience)" -BuildISO -SourceISO D:\ISOs\Windows_Server_2025.iso -AdministratorPassword P@ssw0rd!
.EXAMPLE
# Create an answer file & ISO for Windows Server 2025 Standard (Desktop Experience)
.\New-ServerUnattended.ps1 -OutputDir C:\Temp -Edition "Windows Server 2025 Standard (Desktop Experience)" -BuildISO -SourceISO D:\ISOs\Windows_Server_2025.iso -AdministratorPassword P@ssw0rd!
.EXAMPLE
# Create a VM and boot it from the unattended ISO
.\New-ServerVM.ps1 -Name WS2025-DC -VHDXPath D:\VMs -ISOPath C:\Temp\Windows_Server_2025_Standard_Desktop_Experience-Unattended.iso -SwitchName "Lab" -EnableTPM
Start-VM WS2025-DC
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory=$false)][string]$OutputDir = "$PSScriptRoot\Output",
	[Parameter(Mandatory=$false)][string]$Edition = "Windows Server 2025 Standard (Desktop Experience)",
	[Parameter(Mandatory=$false)][string]$TimeZone = "Romance Standard Time",
	[Parameter(Mandatory=$false)][string]$ProductKey = "",
	[Parameter(Mandatory=$false)][System.Security.SecureString]$AdministratorPassword,
	[switch]$BuildISO,
	[Parameter(Mandatory=$false)][string]$SourceISO = ""
)

$unattendXml = @"
</InstallFrom>
</component>
</settings>
<settings pass="specialize">
<component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<InputLocale>en-US</InputLocale>
<SystemLocale>en-US</SystemLocale>
<UILanguage>en-US</UILanguage>
<UserLocale>en-US</UserLocale>
</component>
<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<ComputerName>*</ComputerName>
<TimeZone>$TimeZone</TimeZone>
$adminPassXml
<OOBE>
<HideEULAPage>true</HideEULAPage>
<NetworkLocation>Work</NetworkLocation>
<ProtectYourPC>3</ProtectYourPC>
</OOBE>
</component>
<component name="Microsoft-Windows-ServerManager-SvrMgrNc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<DoNotOpenServerManagerAtLogon>true</DoNotOpenServerManagerAtLogon>
</component>
</settings>
<settings pass="oobeSystem">
<component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<InputLocale>en-US</InputLocale>
<SystemLocale>en-US</SystemLocale>
<UILanguage>en-US</UILanguage>
<UserLocale>en-US</UserLocale>
</component>
<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<RegisteredOwner>IT</RegisteredOwner>
<RegisteredOrganization>IT</RegisteredOrganization>
</component>
</settings>
<settings pass="firstLogonCommands">
<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
<FirstLogonCommands>
<SynchronousCommand wcm:action="add"><Order>1</Order><Description>Enable WinRM</Description><CommandLine>powershell -ExecutionPolicy Bypass -Command "Enable-PSRemoting -SkipNetworkProfileCheck -Force; Set-Service WinRM -StartupType Automatic; Restart-Service WinRM"</CommandLine></SynchronousCommand>
<SynchronousCommand wcm:action="add"><Order>2</Order><Description>Install OpenSSH.Server</Description><CommandLine>powershell -ExecutionPolicy Bypass -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0; Set-Service sshd -StartupType Automatic; Start-Service sshd"</CommandLine></SynchronousCommand>
<SynchronousCommand wcm:action="add"><Order>3</Order><Description>Install .NET 3.5</Description><CommandLine>powershell -ExecutionPolicy Bypass -Command "Add-WindowsFeature NET-Framework-Core -Source D:\sources\sxs -ErrorAction SilentlyContinue"</CommandLine></SynchronousCommand>
<SynchronousCommand wcm:action="add"><Order>4</Order><Description>Disable IE ESC</Description><CommandLine>powershell -ExecutionPolicy Bypass -Command "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A2B8C5F7-7E04-4a4d-A34C-31C53C105673}' -Name 'IsInstalled' -Value 0; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A2B8C5F8-7E04-4a4d-A34C-31C53C105673}' -Name 'IsInstalled' -Value 0"</CommandLine></SynchronousCommand>
</FirstLogonCommands>
</component>
</settings>
<cpi:offlineImage xmlns:cpi="urn:schemas-microsoft-com:cpi" cpi:source="wim:install.wim#${Edition}" />
</unattend>
"@

$unattendXml | Set-Content -Path $unattendPath -Encoding UTF8
Write-Host "Autounattend.xml written -> $unattendPath" -ForegroundColor Green

# --- Optionally build an ISO containing Autounattend.xml (requires Windows ADK: oscdimg.exe) ---
if ($BuildISO) {
if (-not $SourceISO) { throw "-SourceISO is required with -BuildISO." }
$oscdimg = Get-Command oscdimg.exe -ErrorAction SilentlyContinue
if (-not $oscdimg) { Write-Warning "oscdimg.exe not found. Install Windows ADK or build the ISO manually."; return }

$tmp = Join-Path $env:TEMP ("Unattend_{0}" -f ([Guid]::NewGuid()))
New-Item -ItemType Directory -Path $tmp | Out-Null

# Mount source ISO and copy contents
$img = Mount-DiskImage -ImagePath $SourceISO -PassThru
$vol = ($img | Get-Volume)
robocopy "$($vol.DriveLetter):\" $tmp /MIR | Out-Null

# Place Autounattend.xml at root
Copy-Item $unattendPath (Join-Path $tmp 'Autounattend.xml') -Force

# Build ISO
$outIso = Join-Path $OutputDir ("{0}-Unattended.iso" -f ($Edition -replace '[^A-Za-z0-9]+','_'))
& $oscdimg "-m" "-o" "-u2" "-udfver102" "$tmp" "$outIso" | Out-Null

Dismount-DiskImage -ImagePath $SourceISO | Out-Null
Remove-Item $tmp -Recurse -Force

Write-Host "ISO created -> $outIso" -ForegroundColor Green
}