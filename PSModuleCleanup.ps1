<#
.SYNOPSIS
    Cleans up PowerShell module.
#>

### Remove old versions of PS Modules
$Mods = Get-Module -ListAvailable
foreach ($Mod in $Mods){
    Write-Host "Checking $($mod.name)"
    $latest = Get-InstalledModule $mod.name
    $specificmods = Get-InstalledModule $mod.name -AllVersions
    Write-Host "$($specificmods.count) versions of this module found [ $($mod.name) ]"
    foreach ($sm in $specificmods){
        if ($sm.version -ne $latest.version){
	        Write-Host "Currently uninstalling $($sm.name) - $($sm.version) [latest is $($latest.version)]"
	        $sm | Uninstall-Module -Force
	        Write-Host "Finished uninstalling $($sm.name) - $($sm.version)"
            Write-Host "    --------"
	    }
    }
    Write-Host "------------------------"
}
Write-Host "REMOVAL COMPLETE"