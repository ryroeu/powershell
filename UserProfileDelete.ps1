#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Deletes user profile.
#>

[CmdletBinding()]
param(
    [string]$ComputersPath = (Join-Path -Path $PSScriptRoot -ChildPath 'Computers.txt'),
    [string]$LogPath = (Join-Path -Path $PSScriptRoot -ChildPath 'UserProfileDelete.log')
)

$isWindowsPlatform = ($IsWindows -eq $true) -or ($env:OS -eq 'Windows_NT')
if (-not $isWindowsPlatform) {
    throw 'UserProfileDelete.ps1 is a Windows-only script.'
}

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
}
catch {
    throw 'Unable to load System.Windows.Forms. Run this script on Windows with the desktop runtime available.'
}

if (-not (Test-Path -LiteralPath $ComputersPath)) {
    throw ('Computer list not found: {0}' -f $ComputersPath)
}

$logDirectory = Split-Path -Path $LogPath -Parent
if ($logDirectory -and -not (Test-Path -LiteralPath $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}

$script:Computers = Get-Content -Path $ComputersPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique

if (-not $script:Computers) {
    throw ('No computer names were found in {0}' -f $ComputersPath)
}

$script:LogPath = $LogPath
$script:Form = $null
$script:ListBox = $null
$script:StatusLabel = $null

function Write-ProfileLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Add-Content -Path $script:LogPath -Value ('{0:s} {1}' -f (Get-Date), $Message)
}

function Get-ProfileName {
    $profileNames = [System.Collections.Generic.List[string]]::new()

    foreach ($computer in $script:Computers) {
        try {
            $profiles = Get-CimInstance -ComputerName $computer -ClassName Win32_UserProfile -ErrorAction Stop |
                Where-Object { $_.LocalPath -like 'C:\Users\*' -and -not $_.Special }

            foreach ($userProfile in $profiles) {
                $profileNames.Add([System.IO.Path]::GetFileName($userProfile.LocalPath))
            }
        }
        catch {
            $message = 'Failed to query profiles on {0}: {1}' -f $computer, $_.Exception.Message
            Write-Warning $message
            Write-ProfileLog -Message $message
        }
    }

    $profileNames | Sort-Object -Unique
}

function Remove-SelectedProfile {
    $selectedUsers = @($script:ListBox.SelectedItems | ForEach-Object { $_.ToString() })

    if (-not $selectedUsers) {
        [System.Windows.Forms.MessageBox]::Show('Select one or more profiles to delete first.')
        return
    }

    foreach ($userName in $selectedUsers) {
        $profilePath = 'C:\Users\{0}' -f $userName

        foreach ($computer in $script:Computers) {
            try {
                $userProfile = Get-CimInstance -ComputerName $computer -ClassName Win32_UserProfile -ErrorAction Stop |
                    Where-Object LocalPath -eq $profilePath

                if (-not $userProfile) {
                    $message = 'INFO: {0} profile does not exist on {1}' -f $profilePath, $computer
                    Write-ProfileLog -Message $message
                    continue
                }

                $userProfile | Remove-CimInstance -ErrorAction Stop
                $message = '{0} has been deleted from {1}' -f $profilePath, $computer
                Write-Output $message
                Write-ProfileLog -Message $message
            }
            catch {
                $message = 'ERROR: Failed to delete {0} on {1}: {2}' -f $profilePath, $computer, $_.Exception.Message
                Write-Warning $message
                Write-ProfileLog -Message $message
            }
        }
    }

    $script:StatusLabel.Text = 'Deletion complete. Review the log for details.'
    [System.Windows.Forms.MessageBox]::Show(('Deletion complete. Review the log at {0}' -f $script:LogPath))
}

function Show-ProfileDeletionForm {
    $profileNames = @(Get-ProfileNames)

    $script:Form = New-Object System.Windows.Forms.Form
    $script:Form.Text = 'Delete Remote User Profiles'
    $script:Form.Size = New-Object System.Drawing.Size(420, 380)
    $script:Form.StartPosition = 'CenterScreen'
    $script:Form.TopMost = $true

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
    $titleLabel.Size = New-Object System.Drawing.Size(390, 20)
    $titleLabel.Text = 'Select one or more profile folders to remove from the listed computers:'
    $script:Form.Controls.Add($titleLabel)

    $script:ListBox = New-Object System.Windows.Forms.ListBox
    $script:ListBox.Location = New-Object System.Drawing.Point(10, 35)
    $script:ListBox.Size = New-Object System.Drawing.Size(390, 220)
    $script:ListBox.SelectionMode = 'MultiExtended'
    foreach ($profileName in $profileNames) {
        [void]$script:ListBox.Items.Add($profileName)
    }
    $script:Form.Controls.Add($script:ListBox)

    $deleteButton = New-Object System.Windows.Forms.Button
    $deleteButton.Location = New-Object System.Drawing.Point(100, 295)
    $deleteButton.Size = New-Object System.Drawing.Size(95, 28)
    $deleteButton.Text = 'Delete Profile'
    $deleteButton.Add_Click({ Remove-SelectedProfiles })
    $script:Form.Controls.Add($deleteButton)

    $logButton = New-Object System.Windows.Forms.Button
    $logButton.Location = New-Object System.Drawing.Point(205, 295)
    $logButton.Size = New-Object System.Drawing.Size(95, 28)
    $logButton.Text = 'View Log'
    $logButton.Add_Click({
            if (Test-Path -LiteralPath $script:LogPath) {
                Invoke-Item -Path $script:LogPath
            }
        })
    $script:Form.Controls.Add($logButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(310, 295)
    $cancelButton.Size = New-Object System.Drawing.Size(90, 28)
    $cancelButton.Text = 'Close'
    $cancelButton.Add_Click({ $script:Form.Close() })
    $script:Form.Controls.Add($cancelButton)

    $script:StatusLabel = New-Object System.Windows.Forms.Label
    $script:StatusLabel.Location = New-Object System.Drawing.Point(10, 265)
    $script:StatusLabel.Size = New-Object System.Drawing.Size(390, 20)
    $script:StatusLabel.Text = 'Ready.'
    $script:Form.Controls.Add($script:StatusLabel)

    [void]$script:Form.ShowDialog()
}

Show-ProfileDeletionForm
