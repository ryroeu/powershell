<#
.SYNOPSIS
    Moves 2 new ou.
#>

Move-ADObject –Identity “CN=ny-pc-b32-23,OU=Computers,OU=Florida,OU=USA,DC=theitbros,DC=com” -TargetPath "OU=Computers,OU=California,OU=USA,DC=theitbros,DC=com"