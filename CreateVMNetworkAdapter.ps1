### Create New Network Adapter on VM ###
Add-VMNetworkAdapter -VM "NameOfVM" `
                     -SwitchName "NameOfVswitch" `
                     -ComputerName "HyperVhostName" `
                     -Name "NameOfNewAdapter" `
                     -IsLegacy $false