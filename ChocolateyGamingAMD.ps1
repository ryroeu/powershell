# Install Chocolatey
Set-ExecutionPolicy Unrestricted -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Chocolatey Extensions and Updates
choco install chocolateygui -y
choco install chocolateypackageupdater -y
choco upgrade chocolatey -y

# AMD
choco install amd-ryzen-chipset -y

# BitDefender
choco install bitdefender-usb-immunizer -y
choco install trafficlight-chrome -y
choco install trafficlight-firefox -y

# Browsers
choco install firefox -y
choco install googlechrome -y
choco install microsoft-edge -y
choco install waterfox -y

# CPU-Z
choco install cpu-z -y
choco install hwmonitor -y

# Gaming
choco install discord -y
choco install ea-app -y
choco install steam -y
choco install ubisoft-connect -y

# Google
choco install googledrive -y
choco install googleearthpro -y

# Intel
choco install intel-dsa -y
choco install intel-graphics-driver -y

# Java
choco install openjdk -y

# Microsoft
choco install dotnet -y
choco install dotnetfx -y
choco install microsoft-teams -y
choco install microsoft-windows-terminal -y
choco install nugetpackagemanager -y
choco install office365business -y
choco install onedrive -y
choco install onenote -y
choco install powershell-core -y
choco install powertoys -y
choco install psexec -y
choco install pstools -y
choco install pswindowsupdate -y
choco install rsat -y
choco install sysinternals -y
choco install vcredist140 -y
choco install vscode -y
choco install vscode-powershell -y

# Nord
choco install nordpass -y
choco install nordvpn -y

# Proton
choco install protonvpn -y

# Utilities - Network
choco install advanced-ip-scanner -y

# Miscellaneous
choco install 7zip -y
choco install adobereader -y
choco install ccleaner -y
choco install crystaldiskinfo -y
choco install dependencywalker -y
choco install dropbox -y
choco install greenshot -y
choco install itunes -y
choco install speedtest -y
choco install treesizefree -y
choco install utorrent -y