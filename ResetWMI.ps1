<#
.SYNOPSIS
    Resets WMI.
#>

function DisableService([System.ServiceProcess.ServiceController]$svc) { 
    Set-Service -Name $svc.Name -StartupType Disabled 
}

function EnableServiceAuto([System.ServiceProcess.ServiceController]$svc) { 
    Set-Service -Name $svc.Name -StartupType Automatic 
}

function StopService([System.ServiceProcess.ServiceController]$svc) {
    [string]$dep = ([string]::Empty)
    foreach ($depsvc in $svc.DependentServices) { 
        $dep += $depsvc.DisplayName + ", "
    }
    Write-Host "Stopping $($svc.DisplayName) and its dependent services ($dep)"
    $svc.Stop()
    $svc.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped)
    Write-Host "Stopped $($svc.DisplayName)"
}

function StartService([System.ServiceProcess.ServiceController]$svc, [bool]$handleDependentServices) {
    if ($handleDependentServices) { 
        Write-Host "Starting $($svc.DisplayName) and its dependent services" 
    }
    else { 
        Write-Host "Starting $($svc.DisplayName)" 
    }
    if (!$svc.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
        try {
            $svc.Start()
            $svc.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running)
        }
        catch { }
    }
    Write-Host "Started $($svc.DisplayName)"
    if ($handleDependentServices) {
        [System.ServiceProcess.ServiceController]$depsvc = $null;
        foreach ($depsvc in $svc.DependentServices) {
            if ($depsvc.StartType -eq [System.ServiceProcess.ServiceStartMode]::Automatic) { 
                StartService $depsvc $handleDependentServices }
        }
    }
}

function RegSvr32([string]$path) {
    Write-Host "Registering $path"
    regsvr32.exe $path /s
}

function RegisterMof([System.IO.FileSystemInfo]$item) {
    [bool]$register = $true
    Write-Host "Inspecting: $($item.FullName)"
    if ($item.Name.ToLowerInvariant().Contains('uninstall')) {
        $register = $false
        Write-Host "Skipping - uninstall file: $($item.FullName)"
    }
    elseif ($item.Name.ToLowerInvariant().Contains('remove')) {
        $register = $false
        Write-Host "Skipping - remove file: $($item.FullName)"
    }
    else {
        $txt = Get-Content $item.FullName
        if ($txt.Contains('#pragma autorecover')) {
            $register = $false
            Write-Host "Skipping - autorecover: $($item.FullName)"
        }   

        elseif ($txt.Contains('#pragma deleteinstance')) {
            $register = $false
            Write-Host "Skipping - deleteinstance: $($item.FullName)"
        }
        elseif ($txt.Contains('#pragma deleteclass')) {
            $register = $false
            Write-Host "Skipping - deleteclass: $($item.FullName)"
        }
    }
    if ($register) {
        Write-Host "Registering $($item.FullName)"
        mofcomp $item.FullName
    }
}

function HandleFSO([System.IO.FileSystemInfo]$item, [string]$targetExt) {
    if ($item.Extension -ne [string]::Empty) {
        if ($targetExt -eq 'dll') {
            if ($item.Extension.ToLowerInvariant() -eq '.dll') { 
                RegSvr32 $item.FullName 
            }
        }
        elseif ($targetExt -eq 'mof') {
            if (($item.Extension.ToLowerInvariant() -eq '.mof') -or ($item.Extension.ToLowerInvariant() -eq '.mfl')) { 
                RegisterMof $item 
            }
        }
    }
}

# get Winmgmt service
[System.ServiceProcess.ServiceController]$wmisvc = Get-Service 'winmgmt'

# disable winmgmt service
DisableService $wmisvc

# stop winmgmt service
StopService $wmisvc

# get wbem folder
[string]$wbempath = [Environment]::ExpandEnvironmentVariables("%windir%\system32\wbem")
[System.IO.FileSystemInfo[]]$itemlist = Get-ChildItem $wbempath -Recurse | Where-Object {$_.FullName.Contains('AutoRecover') -ne $true}
[System.IO.FileSystemInfo]$item = $null

# walk dlls
foreach ($item in $itemlist) { 
    HandleFSO $item 'dll' 
}

# call /regserver method on WMI private server executable
wmiprvse /regserver

# call /resetrepository method on WinMgmt service executable
winmgmt /resetrepository

# enable winmgmt service
EnableServiceAuto $wmisvc

# start winmgmt service
StartService $wmisvc $true

# walk MOF / MFLs
foreach ($item in $itemlist) { 
    HandleFSO $item 'mof' 
}