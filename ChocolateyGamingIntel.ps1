# Set Execution Policy
Set-ExecutionPolicy Unrestricted -Scope Process -Force

# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Enable Global Confirmation
choco feature enable -n allowGlobalConfirmation

# Chocolatey Extensions and Updates
choco install chocolatey-core.extension 
choco install chocolateygui 
choco install chocolateypackageupdater 

# BitDefender
choco install bitdefender-usb-immunizer 
choco install trafficlight-chrome 
choco install trafficlight-firefox 

# Browsers
choco install firefox 
choco install googlechrome 
choco install waterfox 

# CPU-Z
choco install cpu-z 
choco install hwmonitor 

# Gaming
choco install discord 
choco install ea-app 
choco install steam 
choco install ubisoft-connect 

# Google
choco install googledrive 
choco install googleearthpro 

# Intel
choco install intel-dsa 
choco install intel-graphics-driver 

# Java
choco install openjdk 

# Microsoft
choco install dotnet 
choco install dotnetfx 
choco install microsoft-teams 
choco install microsoft-windows-terminal 
choco install nugetpackagemanager 
choco install office365business 
choco install onedrive 
choco install onenote 
choco install powershell-core 
choco install powertoys 
choco install psexec 
choco install pstools 
choco install rsat 
choco install sysinternals 
choco install vcredist140 
choco install vscode 
choco install vscode-powershell 

# Nord
choco install nordpass 
choco install nordvpn 

# Proton
choco install protonvpn 

# Utilities - Network
choco install advanced-ip-scanner 

# Miscellaneous
choco install 7zip 
choco install adobereader 
choco install crystaldiskinfo 
choco install dependencywalker 
choco install dropbox 
choco install speedtest 
choco install treesizefree 