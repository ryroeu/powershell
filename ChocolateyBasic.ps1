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

# AWS
choco install awscli -y
choco install awstools.powershell -y

# Azure
choco install az.powershell -y
choco install azure-cli -y

# Browsers
choco install brave -y
choco install firefox -y
choco install googlechrome -y
choco install waterfox -y

# DevOps
choco install python -y
choco install sudo -y

# Docker
choco install docker-cli -y

# Gaming
choco install discord -y

# Git
choco install gh -y
choco install github-desktop -y
choco install git -y
choco install git-credential-manager-for-windows -y

# HashiCorp
choco install consul -y
choco install packer -y
choco install terraform -y
choco install vagrant -y
choco install vault -y

# Java
choco install openjdk -y

# Microsoft
choco install dotnet -y
choco install dotnetfx -y
choco install microsoft-teams -y
choco install nugetpackagemanager -y
choco install office365business -y
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
choco install vscode-java -y
choco install vscode-powershell -y
choco install vscode-yaml -y

#PDQ
choco install pdq-deploy -y
choco install pdq-inventory -y

# Proton
choco install protonvpn -y

# vmWare
choco install vmware-powercli-psmodule -y
choco install vmware-tools -y
choco install vmwareworkstation -y

# Zoom
choco install zoom -y

# Utilities - FTP
choco install filezilla -y
choco install winscp -y

# Utilities - Network
choco install advanced-ip-scanner -y
choco install nmap -y
choco install wireshark -y

# Utilities - Remote
choco install openvpn -y
choco install putty -y
choco install royalts-v7-arm64 -y

# Miscellaneous
choco install 7zip -y
choco install adobereader -y
choco install authy-desktop -y
choco install crystaldiskinfo -y
choco install dependencywalker -y
choco install greenshot -y
choco install speedtest -y
choco install treesizefree -y
choco install utorrent -y
