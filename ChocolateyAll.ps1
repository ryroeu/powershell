# Set Execution Policy
Set-ExecutionPolicy Unrestricted -Scope Process -Force

# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Enable Global Confirmation
choco feature enable -n allowGlobalConfirmation

# Chocolatey Extensions and Updates
choco install chocolatey-core.extension -y
choco install chocolateygui -y
choco install chocolateypackageupdater -y

# AMD
choco install amd-ryzen-chipset -y

# AWS
choco install amazon-workspaces -y
choco install aws-iam-authenticator -y
choco install awscli -y
choco install awstools.powershell -y

# Azure
choco install az.powershell -y
choco install azure-cli -y
choco install azure-functions-core-tools -y
choco install microsoftazurestorageexplorer -y

# BitDefender
choco install bitdefender-usb-immunizer -y
choco install trafficlight-chrome -y
choco install trafficlight-firefox -y

# Browsers
choco install chromium -y
choco install firefox -y
choco install googlechrome -y
choco install tor-browser -y
choco install waterfox -y

# CPU-Z
choco install cpu-z -y
choco install hwmonitor -y

# DevOps
choco install busybox -y
choco install curl -y
choco install go -y
choco install hadoop -y
choco install jenkins -y
choco install jenkins-x -y
choco install kubernetes-cli -y
choco install nginx -y
choco install octopustools -y
choco install octopusdeploy -y
choco install octopusdeploy.tentacle -y
choco install python -y
choco install rabbitmq -y
choco install ruby -y
choco install sandboxie -y
choco install serverless -y
choco install squid -y
choco install sublimetext4 -y
choco install sudo -y
choco install vim -y

# Docker
choco install docker-cli -y
choco install docker-compose -y
choco install docker-desktop -y

# Egnyte
choco install egnyte-desktop-app -y

# ESET
choco install eset-internet-security -y
choco install eset-nod32-antivirus -y

# Gaming
choco install discord -y
choco install ea-app -y
choco install ubisoft-connect -y

# Git
choco install gh -y
choco install github-desktop -y
choco install git -y
choco install git-credential-manager-for-windows -y

# Google
choco install googledrive -y
choco install google-voice-desktop -y
choco install googleearthpro -y

# HashiCorp
choco install consul -y
choco install packer -y
choco install terraform -y
choco install vagrant -y
choco install vault -y

# Intel
choco install intel-dsa -y
choco install intel-graphics-driver -y

# Java
choco install openjdk -y
choco install jre8 -y

# Microsoft
choco install dotnet -y
choco install dotnetfx -y
choco install microsoft-teams -y
choco install microsoft-windows-terminal -y
choco install nugetpackagemanager -y
choco install office365business -y
choco install onedrive -y
choco install onenote -y
choco install powerbi -y
choco install powershell-core -y
choco install powertoys -y
choco install psexec -y
choco install pstools -y
choco install rsat -y
choco install sql-server-management-studio -y
choco install sysinternals -y
choco install vcredist140 -y
choco install vscode -y
choco install vscode-ansible -y
choco install vscode-go -y
choco install vscode-java -y
choco install vscode-powershell -y
choco install vscode-yaml -y

# Nord
choco install nordpass -y
choco install nordvpn -y

# nVidia
choco install geforce-experience -y
choco install geforce-game-ready-driver -y
choco install nvidia-display-driver -y
choco install nvidia-geforce-now -y

#PDQ
choco install pdq-deploy -y
choco install pdq-inventory -y

# Proton
choco install protonvpn -y

# Ubiquiti
choco install ubiquiti-unifi-controller -y

# VirtualBox
choco install virtualbox -y
choco install virtualbox-guest-additions-guest.install -y

# vmWare
choco install vmware-powercli-psmodule -y
choco install vmware-tools -y
choco install vmwareworkstation -y

# Zoom
choco install zoom -y

# Utilities - FTP
choco install filezilla -y
choco install filezilla.server -y
choco install winscp -y

# Utilities - Network
choco install advanced-ip-scanner -y
choco install nmap -y
choco install wireshark -y

# Utilities - Remote
choco install openvpn -y
choco install putty -y
choco install royalts-v7-x64 -y
#choco install royalts-v7-arm64 -y
choco install teamviewer -y
choco install teamviewer-qs -y

# Miscellaneous
choco install 7zip -y
choco install adobereader -y
choco install crystaldiskinfo -y
choco install dependencywalker -y
choco install dropbox -y
choco install slack -y
choco install speedtest -y
choco install treesizefree -y