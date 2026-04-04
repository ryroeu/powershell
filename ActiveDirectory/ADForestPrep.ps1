<#
.SYNOPSIS
    Manages active directory forest prep.
#>

# Prepare the Forest
adprep.exe /forestprep /forest lucernpub.com /user EntAdmin /userdomain lucernpub.com /password P@ssw0rd
# Prepare the Domain
adprep.exe /domainprep /domain lucernpub.com /user DomAdm /userdomain lucernpub /password P@ssw0rd
# Fix Group Policy Permissions
adprep.exe /domainprep /gpprep /domain lucernpub.com /user DomAdm /userdomain lucernpub.com /password P@ssw0rd
# Raise FFL
Set-ADForestMode lucernpub.com Windows2016Forest