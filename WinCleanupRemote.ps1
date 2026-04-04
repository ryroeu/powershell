#Requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkstationGroup = 'Workstations',

    [switch]$ClearRemoteRecycleBin
)

$computers = Get-ADGroupMember -Identity $WorkstationGroup -Recursive |
    Where-Object objectClass -eq 'computer' |
    Select-Object -ExpandProperty Name

if (-not $computers) {
    Write-Warning ('No computer accounts were found in the "{0}" group.' -f $WorkstationGroup)
    return
}

$cleanupScript = {
    param(
        [bool]$ClearRecycleBin
    )

    $windowsTemp = Join-Path -Path $env:windir -ChildPath 'Temp\*'
    $softwareDistribution = Join-Path -Path $env:windir -ChildPath 'SoftwareDistribution\Download\*'

    Remove-Item -Path $windowsTemp -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $softwareDistribution -Recurse -Force -ErrorAction SilentlyContinue

    if ($ClearRecycleBin) {
        Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
    }

    [pscustomobject]@{
        ComputerName       = $env:COMPUTERNAME
        ClearedWindowsTemp = $true
        ClearedWUDownloads = $true
        ClearedRecycleBin  = $ClearRecycleBin
    }
}

foreach ($computer in $computers) {
    if (-not $PSCmdlet.ShouldProcess($computer, 'Clear Windows temp files and update download cache')) {
        continue
    }

    try {
        Invoke-Command -ComputerName $computer -ScriptBlock $cleanupScript -ArgumentList $ClearRemoteRecycleBin.IsPresent
    }
    catch {
        Write-Warning ('Failed to clean {0}: {1}' -f $computer, $_.Exception.Message)
    }
}
