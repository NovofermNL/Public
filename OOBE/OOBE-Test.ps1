<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11 via OSDCloud en voert na installatie automatisch PostInstall.ps1 uit vanaf GitHub
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installeer/Importeer benodigde modules
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Installeren van OSD module (buiten WinPE)"
    Install-Module OSD -Force
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module OSD wordt overgeslagen"
}
Import-Module OSD -Force

Install-Module AutopilotOOBE -Force
Install-Module OOBEDeploy -Force
Import-Module AutopilotOOBE -Force
Import-Module OOBEDeploy -Force

# Start de installatie van Windows 11
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume -ZTI

# Laat automatisch PostInstall.ps1 vanaf GitHub uitvoeren ná installatie
Start-OOBEDeploy -ScriptUrl "https://raw.githubusercontent.com/NovofermNL/Public/main/PostInstall.ps1" -PostAction Restart
