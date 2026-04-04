<#
.SYNOPSIS
    Adds Windows features.
#>

# Istall Windows Feature on remote computer
Install-WindowsFeature -Name "feature_name" -computerName "computer_name" -Restart