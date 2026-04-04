<#
.SYNOPSIS
    Adds feature.
#>

### Add a Windows Feature ###
Install-WindowsFeature -Name "NameOfFeature" `
                       -ComputerName "TargetComputer" `
                       -Restart