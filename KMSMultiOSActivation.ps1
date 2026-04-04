<#
.SYNOPSIS
    Manages kms multiple operating systems activation.
#>

#### Installs the appropriate KMS client key for the detected OS ####
$OSversion = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
switch -Regex ($OSversion) {
    'Windows 7 Professional'                 {$key = 'HMCNV-VVBFX-7HMBH-CTY9B-B4FXY';break}
    'Windows 7 Enterprise'                   {$key = 'MHF9N-XY6XB-WVXMC-BTDCT-MKKG7';break}
    'Windows 8 Professional'                 {$key = 'NG4HW-VH26C-733KW-K6F98-J8CK4';break}
    'Windows 8 Enterprise'                   {$key = '32JNW-9KQ84-P47T8-D8GGY-CWCK7';break}
    'Windows 8\.1 Professional'              {$key = 'GCRJD-8NW9H-F2CDX-CCM8D-9D6T9';break}
    'Windows 8\.1 Enterprise'               {$key = 'MHF9N-XY6XB-WVXMC-BTDCT-MKKG7';break}
    'Windows 10 Professional'               {$key = 'W269N-WFGWX-YVC9B-4J6C9-T83GX';break}
    'Windows 10 Enterprise'                 {$key = 'NPPR9-FWDCX-D2C8J-H872K-2YT43';break}
    'Windows 11 Pro'                        {$key = 'W269N-WFGWX-YVC9B-4J6C9-T83GX';break}
    'Windows 11 Enterprise'                 {$key = 'NPPR9-FWDCX-D2C8J-H872K-2YT43';break}
    'Windows Server 2008 Standard'          {$key = 'TM24T-X9RMF-VWXK6-X8JC9-BFGM2';break}
    'Windows Server 2008 Datacenter'        {$key = '7M67G-PC374-GR742-YH8V4-TCBY3';break}
    'Windows Server 2008 R2 Standard'       {$key = 'YC6KT-GKW9T-YTKYR-T4X34-R7VHC';break}
    'Windows Server 2008 R2 Datacenter'     {$key = '74YFP-3QFB3-KQT8W-PMXWJ-7M648';break}
    'Windows Server 2012 Standard'          {$key = 'XC9B7-NBPP2-83J2H-RHMBY-92BT4';break}
    'Windows Server 2012 Datacenter'        {$key = '48HP8-DN98B-MYWDG-T2DCC-8W83P';break}
    'Windows Server 2012 R2 Standard'       {$key = 'D2N9P-3P6X9-2R39C-7RTCD-MDVJX';break}
    'Windows Server 2012 R2 Datacenter'     {$key = 'W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9';break}
    'Windows Server 2016 Standard'          {$key = 'WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY';break}
    'Windows Server 2016 Datacenter'        {$key = 'CB7KF-BWN84-R7R2Y-793K2-8XDDG';break}
    'Windows Server 2019 Standard'          {$key = 'N69G4-B89J2-4G8F4-WWYCC-J464C';break}
    'Windows Server 2019 Datacenter'        {$key = 'WMDGN-G9PQG-XVVXX-R3X43-63DFG';break}
    'Windows Server 2022 Standard'          {$key = 'VDYBN-27WPP-V4HQT-9VMD4-VMK7H';break}
    'Windows Server 2022 Datacenter'        {$key = 'WX4NM-KYWYW-QJJR4-XV3QB-6VM33';break}
    'Windows Server 2025 Standard'          {$key = 'TVRH6-WHNXV-R9WG3-9XRFY-MY832';break}
    'Windows Server 2025 Datacenter'        {$key = 'D764K-2NDRG-47T6Q-P8T8W-YP6DF';break}
}
$KMSservice = Get-CimInstance -Query "SELECT * FROM SoftwareLicensingService"
Write-Debug 'Activating Windows.'
$null = Invoke-CimMethod -InputObject $KMSservice -MethodName "InstallProductKey" -Arguments @{ ProductKey = $key }
$null = Invoke-CimMethod -InputObject $KMSservice -MethodName "RefreshLicenseStatus"
