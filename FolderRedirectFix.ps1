<#
.SYNOPSIS
    Manages folder redirect fix.
#>

### {USER-STRING} ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{USER-STRING}"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "{USER-STRING}" /t "REG_SZ" /d "\\ComputerName\Users\UserName\AppData\Roaming\Microsoft\Windows\Libraries"

### Administrative Tools ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Administrative Tools"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Administrative Tools" /t "REG_SZ" /d "\\ComputerName\Users\UserName\Start Menu\Programs\Administrative Tools"

### AppData ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "AppData"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "AppData" /t "REG_SZ" /d "\\ComputerName\Users\UserName\AppData\Roaming"

### Desktop ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Desktop"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Desktop" /t "REG_SZ" /d "\\ComputerName\Users\UserName\Desktop"

### Favorites ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Favorites"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Favorites" /t "REG_SZ" /d "\\ComputerName\Users\UserName\Favorites"

### My Pictures ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Pictures"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "My Pictures" /t "REG_SZ" /d "\\ComputerName\Users\UserName\Pictures"

### NetHood ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "NetHood"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "NetHood" /t "REG_SZ" /d "\\ComputerName\Users\UserName\AppData\Roaming\Microsoft\Windows\Network Shortcuts"

### Personal ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Personal" /t "REG_SZ" /d "\\ComputerName\Users\UserName\Documents"

### PrintHood ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "PrintHood"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "PrintHood" /t "REG_SZ" /d "\\ComputerName\Users\UserName\AppData\Roaming\Microsoft\Windows\Printer Shortcuts"

### Programs ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Programs"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Programs" /t "REG_SZ" /d "\\ComputerName\Users\UserName\Start Menu\Programs"

### Recent ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Recent"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Recent" /t "REG_SZ" /d "\\ComputerName\Users\UserName\AppData\Roaming\Microsoft\Windows\Recent"

### SendTo ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "SendTo"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "SendTo" /t "REG_SZ" /d "\\ComputerName\Users\UserName\AppData\Roaming\Microsoft\Windows\SendTo"

### Start Menu ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Start Menu"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Start Menu" /t "REG_SZ" /d "\\ComputerName\Users\UserName\Start Menu"

### Startup ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Startup"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Startup" /t "REG_SZ" /d "\\ComputerName\Users\UserName\Start Menu\Programs\Startup"

### Templates ###
REG DELETE "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Templates"
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Templates" /t "REG_SZ" /d "\\ComputerName\Users\UserName\AppData\Roaming\Microsoft\Windows\Templates"
