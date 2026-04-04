<#
.SYNOPSIS
    Creates new text file.
#>

### Create New Text File and Add Content ###
New-Item C:\NewItemFile.txt -Type file
Set-Content C:\NewItemFile.txt "Enter your text here..."
Add-Content C:\NewItemFile.txt "Enter second line of text here..."