<#
.SYNOPSIS
    Creates virtual machine.
#>

### Create New VM ###
New-VM -MemoryStartupBytes "4GB" `
       -Name "NameofVM" `
       -ComputerName "NameOfHyperVhost"
       -Path "C:\Directory\VMfiles" `
       -NewVHDPath "C:\Directory\NameofVHD.vhdx" `
       -BootDevice "VHD" `
       -Generation "2" `
       -SwitchName "NameOfVswitch" `
       -Confirm