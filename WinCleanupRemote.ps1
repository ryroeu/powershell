<#
.SYNOPSIS
    Cleans selected temporary data on remote Windows computers.
#>

#Requires -Modules ActiveDirectory

[CmdletBinding(DefaultParameterSetName = 'Group', SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Computer')]
    [string[]]$ComputerName,

    [Parameter(ParameterSetName = 'Group')]
    [string]$WorkstationGroup = 'Workstations',

    [pscredential]$Credential,

    [switch]$ClearWindowsUpdateCache,

    [switch]$ClearRecycleBin,

    [switch]$SkipWindowsTemp
)

$computers = if ($PSCmdlet.ParameterSetName -eq 'Computer') {
    $ComputerName
}
else {
    Get-ADGroupMember -Identity $WorkstationGroup -Recursive |
        Where-Object ObjectClass -eq 'computer' |
        Select-Object -ExpandProperty Name
}

$cleanupScript = {
    param($ClearUpdateCache, $ClearBin, $SkipTemp)

    $removed = 0
    $errors = [Collections.Generic.List[string]]::new()
    function Remove-DirectoryContent {
        [CmdletBinding(SupportsShouldProcess)]
        param([string]$LiteralDirectory)
        if (-not (Test-Path -LiteralPath $LiteralDirectory -PathType Container)) { return }
        $itemCount = 0
        foreach ($item in Get-ChildItem -LiteralPath $LiteralDirectory -Force -ErrorAction SilentlyContinue) {
            if (-not $PSCmdlet.ShouldProcess($item.FullName, 'Remove')) { continue }
            try { Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop; $itemCount++ }
            catch { $errors.Add("$($item.FullName): $($_.Exception.Message)") }
        }
        $itemCount
    }

    if (-not $SkipTemp) {
        $removed += Remove-DirectoryContent -LiteralDirectory (Join-Path $env:SystemRoot 'Temp') -Confirm:$false
    }
    if ($ClearUpdateCache) {
        $states = @{}
        try {
            foreach ($name in 'BITS', 'wuauserv') {
                $service = Get-Service -Name $name -ErrorAction SilentlyContinue
                if ($service) {
                    $states[$name] = $service.Status
                    if ($service.Status -ne 'Stopped') { Stop-Service -Name $name -Force -ErrorAction Stop }
                }
            }
            $removed += Remove-DirectoryContent -LiteralDirectory (Join-Path $env:SystemRoot 'SoftwareDistribution\Download') -Confirm:$false
        }
        finally {
            foreach ($name in $states.Keys) {
                if ($states[$name] -eq 'Running') { Start-Service -Name $name -ErrorAction SilentlyContinue }
            }
        }
    }
    if ($ClearBin) {
        try { Clear-RecycleBin -Force -Confirm:$false -ErrorAction Stop }
        catch { $errors.Add("Recycle Bin: $($_.Exception.Message)") }
    }

    [pscustomobject]@{ ComputerName = $env:COMPUTERNAME; RemovedItems = $removed; Errors = $errors.ToArray() }
}

foreach ($computer in $computers | Sort-Object -Unique) {
    if (-not $PSCmdlet.ShouldProcess($computer, 'Clean selected Windows data')) { continue }
    $parameters = @{ ComputerName = $computer; ErrorAction = 'Stop' }
    if ($Credential) { $parameters.Credential = $Credential }
    try {
        Invoke-Command @parameters -ScriptBlock $cleanupScript -ArgumentList $ClearWindowsUpdateCache.IsPresent, $ClearRecycleBin.IsPresent, $SkipWindowsTemp.IsPresent
    }
    catch {
        [pscustomobject]@{ ComputerName = $computer; RemovedItems = 0; Errors = @($_.Exception.Message) }
    }
}
