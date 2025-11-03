<# 
.SYNOPSIS
  Retrieve motherboard / chassis / BIOS info using CIM (works on Windows PowerShell 5.1 and PowerShell 7+).

.EXAMPLES
  .\GetMoboInfo.ps1
  .\GetMoboInfo.ps1 -ComputerName server01,server02 -As Json
  .\GetMoboInfo.ps1 -ComputerName server01 -Credential (Get-Credential) -OutCsv .\mobo.csv
#>

[CmdletBinding()]
param(
  [string[]] $ComputerName = $env:COMPUTERNAME,
  [pscredential] $Credential,
  [ValidateSet('Table','Json','Csv')] [string] $As = 'Table',
  [string] $OutCsv
)

$ErrorActionPreference = 'Stop'

# Chassis types map (subset of SMBIOS spec)
$chassisMap = @{
  1='Other'; 2='Unknown'; 3='Desktop'; 4='Low Profile Desktop'; 5='Pizza Box';
  6='Mini Tower'; 7='Tower'; 8='Portable'; 9='Laptop'; 10='Notebook';
  11='Handheld'; 12='Docking Station'; 13='All in One'; 14='Sub Notebook';
  15='Space-saving'; 16='Lunch Box'; 17='Main Server Chassis'; 18='Expansion Chassis';
  19='SubChassis'; 20='Bus Expansion Chassis'; 21='Peripheral Chassis';
  22='RAID Chassis'; 23='Rack Mount Chassis'; 24='Sealed-case PC';
  32='Blade'; 33='Blade Enclosure'; 34='Tablet'; 35='Convertible';
  36='Detachable'; 39='IoT Gateway'; 40='Embedded PC'; 41='Mini PC'; 42='Stick PC'
}

# Build a CIM session option that’s usually safe through firewalls (default WSMan)
$cimOpts = New-CimSessionOption -Protocol Wsman
$cimSessions = @()

try {
  foreach ($comp in $ComputerName) {
    if ($comp -in @('.', 'localhost')) { $comp = $env:COMPUTERNAME }
    $sess = if ($PSBoundParameters.ContainsKey('Credential')) {
      New-CimSession -ComputerName $comp -Credential $Credential -SessionOption $cimOpts
    } else {
      New-CimSession -ComputerName $comp -SessionOption $cimOpts
    }
    $cimSessions += $sess
  }

  $rows = foreach ($s in $cimSessions) {
    try {
      $bb   = Get-CimInstance -ClassName Win32_BaseBoard -CimSession $s
      $bios = Get-CimInstance -ClassName Win32_BIOS -CimSession $s
      $prod = Get-CimInstance -ClassName Win32_ComputerSystemProduct -CimSession $s
      $enc  = Get-CimInstance -ClassName Win32_SystemEnclosure -CimSession $s

      # Some systems report an array in ChassisTypes — take first meaningful value
      $ctype = $null
      if ($enc -and $enc.ChassisTypes) {
        $ctype = ($enc.ChassisTypes | Where-Object { $_ -ne 2 } | Select-Object -First 1) # prefer non-Unknown
        if (-not $ctype) { $ctype = $enc.ChassisTypes[0] }
      }

      [pscustomobject]@{
        ComputerName     = $s.ComputerName
        BaseboardVendor  = $bb.Manufacturer
        BaseboardModel   = $bb.Product
        BaseboardVersion = $bb.Version
        BaseboardSerial  = $bb.SerialNumber
        BIOSVendor       = $bios.Manufacturer
        BIOSVersion      = ($bios.SMBIOSBIOSVersion ?? $bios.BIOSVersion -join ' ')
        BIOSReleaseDate  = [datetime]::ParseExact($bios.ReleaseDate.Substring(0,8),'yyyyMMdd',$null)  # yyyymmdd
        SystemSKU        = $prod.SKUNumber
        SystemUUID       = $prod.UUID
        ChassisType      = if ($ctype) { $chassisMap[$ctype] ?? $ctype } else { $null }
        AssetTag         = $enc.SMBIOSAssetTag
      }
    }
    catch {
      [pscustomobject]@{
        ComputerName     = $s.ComputerName
        BaseboardVendor  = $null
        BaseboardModel   = $null
        BaseboardVersion = $null
        BaseboardSerial  = $null
        BIOSVendor       = $null
        BIOSVersion      = $null
        BIOSReleaseDate  = $null
        SystemSKU        = $null
        SystemUUID       = $null
        ChassisType      = $null
        AssetTag         = $null
        Error            = $_.Exception.Message
      }
    }
  }

  if ($As -eq 'Json') {
    $rows | ConvertTo-Json -Depth 5
  }
  elseif ($As -eq 'Csv' -or $OutCsv) {
    if (-not $OutCsv) { $OutCsv = Join-Path $PWD 'GetMoboInfo.csv' }
    $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutCsv
    Write-Host "CSV written -> $OutCsv" -ForegroundColor Green
  }
  else {
    $rows | Format-Table ComputerName,BaseboardVendor,BaseboardModel,BaseboardSerial,BIOSVersion,ChassisType -Auto
  }

}
finally {
  if ($cimSessions) { $cimSessions | Remove-CimSession -ErrorAction SilentlyContinue }
}
Write-Host "Done." -ForegroundColor Green