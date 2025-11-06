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

# AWS
choco install awscli 
choco install awstools.powershell 

# Azure
choco install az.powershell 
choco install azure-cli 

# Browsers
choco install brave 
choco install firefox 
choco install googlechrome 
choco install waterfox 

# DevOps
choco install python 
choco install sudo 

# Docker
choco install docker-cli 

# Gaming
choco install discord 

# Git
choco install gh 
choco install github-desktop 
choco install git 
choco install git-credential-manager-for-windows 

# HashiCorp
choco install consul 
choco install packer 
choco install terraform 
choco install vagrant 
choco install vault 

# Java
choco install openjdk 

# Microsoft
choco install dotnet 
choco install dotnetfx 
choco install microsoft-teams 
choco install nugetpackagemanager 
choco install office365business 
choco install powershell-core 
choco install powertoys 
choco install psexec 
choco install pstools 
choco install rsat 
choco install sql-server-management-studio 
choco install sysinternals 
choco install vcredist140 
choco install vscode 
choco install vscode-ansible 
choco install vscode-java 
choco install vscode-powershell 
choco install vscodeaml 

#PDQ
choco install pdq-deploy 
choco install pdq-inventory 

# Proton
choco install protonvpn 

# vmWare
choco install vmware-powercli-psmodule 
choco install vmware-tools 
choco install vmwareworkstation 

# Zoom
choco install zoom 

# Utilities - FTP
choco install filezilla 
choco install winscp 

# Utilities - Network
choco install advanced-ip-scanner 
choco install nmap 
choco install wireshark 

# Utilities - Remote
choco install openvpn 
choco install putty 
choco install royalts-v7-arm64 

# Miscellaneous
choco install 7zip 
choco install adobereader 
choco install crystaldiskinfo 
choco install dependencywalker 
choco install speedtest 
choco install treesizefree 