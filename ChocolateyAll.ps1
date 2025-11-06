# Set Execution Policy
Set-ExecutionPolicy Unrestricted -Scope Process -Force
# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Chocolatey Extensions and Updates
choco install chocolatey-core.extension
choco install chocolateygui
choco install chocolateypackageupdater
choco upgrade chocolatey

# AMD
choco install amd-ryzen-chipset

# AWS
choco install amazon-workspaces
choco install aws-iam-authenticator
choco install awscli
choco install awstools.powershell

# Azure
choco install az.powershell
choco install azure-cli
choco install azure-functions-core-tools
choco install microsoftazurestorageexplorer

# BitDefender
choco install bitdefender-usb-immunizer
choco install trafficlight-chrome
choco install trafficlight-firefox

# Browsers
choco install chromium
choco install firefox
choco install googlechrome
choco install microsoft-edge
choco install tor-browser
choco install waterfox

# CPU-Z
choco install cpu-z
choco install hwmonitor

# DevOps
choco install busybox
choco install curl
choco install go
choco install hadoop
choco install jenkins
choco install jenkins-x
choco install kubernetes-cli
choco install nginx
choco install octopustools
choco install octopusdeploy
choco install octopusdeploy.tentacle
choco install python
choco install rabbitmq
choco install ruby
choco install sandboxie
choco install serverless
choco install squid
choco install sublimetext4
choco install sudo
choco install vim

# Docker
choco install docker-cli
choco install docker-compose
choco install docker-desktop

# Egnyte
choco install egnyte-desktop-app

# ESET
choco install eset-internet-security
choco install eset-nod32-antivirus

# Gaming
choco install discord
choco install ea-app
choco install ubisoft-connect

# Git
choco install gh
choco install github-desktop
choco install git
choco install git-credential-manager-for-windows

# Google
choco install googledrive
choco install google-voice-desktop
choco install googleearthpro

# HashiCorp
choco install consul
choco install packer
choco install terraform
choco install vagrant
choco install vault

# Intel
choco install intel-dsa
choco install intel-graphics-driver

# Java
choco install openjdk
choco install jre8

# Microsoft
choco install dotnet
choco install dotnetfx
choco install microsoft-teams
choco install microsoft-windows-terminal
choco install nugetpackagemanager
choco install office365business
choco install onedrive
choco install onenote
choco install powerbi
choco install powershell-core
choco install powertoys
choco install psexec
choco install pstools
choco install pswindowsupdate
choco install rsat
choco install sql-server-management-studio
choco install sysinternals
choco install vcredist140
choco install vscode
choco install vscode-ansible
choco install vscode-go
choco install vscode-java
choco install vscode-powershell
choco install vscode-yaml

# Nord
choco install nordpass
choco install nordvpn

# nVidia
choco install geforce-experience
choco install geforce-game-ready-driver
choco install nvidia-display-driver
choco install nvidia-geforce-now

#PDQ
choco install pdq-deploy
choco install pdq-inventory

# Proton
choco install protonvpn

# Ubiquiti
choco install ubiquiti-unifi-controller

# VirtualBox
choco install virtualbox
choco install virtualbox-guest-additions-guest.install

# vmWare
choco install vmrc
choco install vmware-powercli-psmodule
choco install vmware-tools
choco install vmwarevsphereclient
choco install vmwareworkstation

# Zoom
choco install zoom
choco install zoom-outlook

# Utilities - FTP
choco install filezilla
choco install filezilla.server
choco install winscp

# Utilities - Network
choco install advanced-ip-scanner
choco install nmap
choco install wireshark

# Utilities - Remote
choco install openvpn
choco install putty
choco install royalts-v7-x64
#choco install royalts-v7-arm64
choco install teamviewer
choco install teamviewer-qs

# Miscellaneous
choco install 7zip
choco install adobereader
choco install authy-desktop
choco install ccleaner
choco install citrix-workspace
choco install crystaldiskinfo
choco install datadog-agent
choco install dependencywalker
choco install dropbox
choco install greenshot
choco install itunes
choco install slack
choco install speedtest
choco install treesizefree
choco install utorrent