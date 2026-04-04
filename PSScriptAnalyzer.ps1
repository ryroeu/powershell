<#
.SYNOPSIS
    Manages powershell script analyzer.
#>

Install-Module -Name PSScriptAnalyzer
    or (if already installed)
        Update-Module -Name PSScriptAnalyzer

Invoke-ScriptAnalyzer .\NameOfScript.ps1
