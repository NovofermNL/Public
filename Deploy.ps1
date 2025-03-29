<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11 en verwijdert vooraf AppX provisioned packages
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

#   PreOS - Set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#   Install and Import OSD Module (met WinPE-check)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Updating OSD PowerShell Module (buiten WinPE)"
    Install-Module OSD -Force 
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module OSD wordt overgeslagen"
}

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#   Installeer Windows 11
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

#   Herstart naar OOBE
Restart-Computer
