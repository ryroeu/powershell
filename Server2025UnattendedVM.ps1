<#
.SYNOPSIS
    Creates a valid Autounattend.xml for Windows Server 2022 or 2025 and can build a bootable ISO.
.DESCRIPTION
    The answer file creates a UEFI/GPT layout with EFI, MSR, and Windows partitions, selects an image by
    its exact display name, configures locale and time zone, and can set the local Administrator password.
    Building an ISO requires Windows ADK oscdimg.exe and a source Windows Server ISO.
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'Output'),

    [string]$Edition = 'Windows Server 2025 Standard (Desktop Experience)',

    [string]$TimeZone = 'Romance Standard Time',

    [ValidateSet('en-US', 'en-GB', 'fr-FR', 'de-DE', 'es-ES')]
    [string]$Locale = 'en-US',

    [ValidatePattern('^$|^[A-Za-z0-9]{5}(?:-[A-Za-z0-9]{5}){4}$')]
    [string]$ProductKey,

    [securestring]$AdministratorPassword,

    [switch]$EnableWinRM,

    [switch]$InstallOpenSSHServer,

    [switch]$BuildISO,

    [string]$SourceISO
)

if ($BuildISO -and -not $SourceISO) {
    throw '-SourceISO is required when -BuildISO is specified.'
}

$escape = { param([string]$Value) [Security.SecurityElement]::Escape($Value) }
$escapedEdition = & $escape $Edition
$escapedTimeZone = & $escape $TimeZone
$escapedLocale = & $escape $Locale

$productKeyXml = if ($ProductKey) {
    "<ProductKey><Key>$(& $escape $ProductKey)</Key><WillShowUI>OnError</WillShowUI></ProductKey>"
}
else {
    ''
}

$administratorPasswordXml = ''
if ($AdministratorPassword) {
    $plainTextPassword = [Net.NetworkCredential]::new('', $AdministratorPassword).Password
    try {
        $administratorPasswordXml = @"
        <UserAccounts>
          <AdministratorPassword>
            <Value>$(& $escape $plainTextPassword)</Value>
            <PlainText>true</PlainText>
          </AdministratorPassword>
        </UserAccounts>
"@
    }
    finally {
        $plainTextPassword = $null
    }
    Write-Warning 'The generated answer file contains the Administrator password in plaintext. Protect and delete it after setup.'
}

$firstLogonCommands = [Collections.Generic.List[string]]::new()
$order = 1
if ($EnableWinRM) {
    $firstLogonCommands.Add(@"
          <SynchronousCommand wcm:action="add">
            <Order>$order</Order>
            <Description>Enable PowerShell remoting</Description>
            <CommandLine>powershell.exe -NoProfile -ExecutionPolicy Bypass -Command &quot;Enable-PSRemoting -SkipNetworkProfileCheck -Force&quot;</CommandLine>
          </SynchronousCommand>
"@)
    $order++
}
if ($InstallOpenSSHServer) {
    $firstLogonCommands.Add(@"
          <SynchronousCommand wcm:action="add">
            <Order>$order</Order>
            <Description>Install OpenSSH Server</Description>
            <CommandLine>powershell.exe -NoProfile -ExecutionPolicy Bypass -Command &quot;Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0; Set-Service sshd -StartupType Automatic; Start-Service sshd&quot;</CommandLine>
          </SynchronousCommand>
"@)
}
$firstLogonXml = if ($firstLogonCommands.Count -gt 0) {
    "<FirstLogonCommands>`n$($firstLogonCommands -join "`n")`n        </FirstLogonCommands>"
}
else {
    ''
}

$unattendXml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>$escapedLocale</UILanguage></SetupUILanguage>
      <InputLocale>$escapedLocale</InputLocale>
      <SystemLocale>$escapedLocale</SystemLocale>
      <UILanguage>$escapedLocale</UILanguage>
      <UserLocale>$escapedLocale</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add"><Order>1</Order><Size>100</Size><Type>EFI</Type></CreatePartition>
            <CreatePartition wcm:action="add"><Order>2</Order><Size>16</Size><Type>MSR</Type></CreatePartition>
            <CreatePartition wcm:action="add"><Order>3</Order><Extend>true</Extend><Type>Primary</Type></CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label><Letter>C</Letter></ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallFrom><MetaData wcm:action="add"><Key>/IMAGE/NAME</Key><Value>$escapedEdition</Value></MetaData></InstallFrom>
          <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
          <WillShowUI>OnError</WillShowUI>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>Administrator</FullName>
        <Organization>IT</Organization>
        $productKeyXml
      </UserData>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <InputLocale>$escapedLocale</InputLocale><SystemLocale>$escapedLocale</SystemLocale><UILanguage>$escapedLocale</UILanguage><UserLocale>$escapedLocale</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <ComputerName>*</ComputerName><TimeZone>$escapedTimeZone</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      $administratorPasswordXml
      <OOBE><HideEULAPage>true</HideEULAPage><ProtectYourPC>1</ProtectYourPC></OOBE>
      $firstLogonXml
    </component>
  </settings>
</unattend>
"@

$null = New-Item -ItemType Directory -Path $OutputDirectory -Force
$unattendPath = Join-Path $OutputDirectory 'Autounattend.xml'
if ($PSCmdlet.ShouldProcess($unattendPath, 'Write unattended setup answer file')) {
    $unattendXml | Set-Content -LiteralPath $unattendPath -Encoding utf8
}

if (-not $BuildISO) {
    Get-Item -LiteralPath $unattendPath
    return
}

$oscdimg = Get-Command oscdimg.exe -ErrorAction Stop
$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ('WindowsServerUnattend_{0}' -f [guid]::NewGuid())
$mounted = $false
try {
    if (-not $PSCmdlet.ShouldProcess($SourceISO, 'Build bootable unattended Windows Server ISO')) {
        return
    }

    $null = New-Item -ItemType Directory -Path $temporaryDirectory
    $image = Mount-DiskImage -ImagePath $SourceISO -PassThru -ErrorAction Stop
    $mounted = $true
    $volume = $image | Get-Volume
    & "$env:SystemRoot\System32\robocopy.exe" "$($volume.DriveLetter):\" $temporaryDirectory /MIR /R:2 /W:1 | Out-Null
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy.exe failed with exit code $LASTEXITCODE."
    }

    Copy-Item -LiteralPath $unattendPath -Destination (Join-Path $temporaryDirectory 'Autounattend.xml') -Force
    $outputIso = Join-Path $OutputDirectory ("{0}-Unattended.iso" -f ($Edition -replace '[^A-Za-z0-9]+', '_'))
    $biosBoot = Join-Path $temporaryDirectory 'boot\etfsboot.com'
    $uefiBoot = Join-Path $temporaryDirectory 'efi\microsoft\boot\efisys.bin'
    $bootData = "-bootdata:2#p0,e,b$biosBoot#pEF,e,b$uefiBoot"
    & $oscdimg.Source -m -o -u2 -udfver102 $bootData $temporaryDirectory $outputIso | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "oscdimg.exe failed with exit code $LASTEXITCODE."
    }
    Get-Item -LiteralPath $outputIso
}
finally {
    if ($mounted) {
        Dismount-DiskImage -ImagePath $SourceISO -ErrorAction SilentlyContinue | Out-Null
    }
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
