<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11, installeert benodigde modules en start post-install taken via OOBEDeploy
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

#   TLS 1.2 afdwingen
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#   Installeer en importeer OSD-module (WinPE-check)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Updating OSD PowerShell Module (buiten WinPE)"
    Install-Module OSD -Force 
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module OSD wordt overgeslagen"
}
Import-Module OSD -Force

#   Installeer modules voor post-install automatisering
Install-Module AutopilotOOBE -Force
Install-Module OOBEDeploy -Force
Import-Module AutopilotOOBE -Force
Import-Module OOBEDeploy -Force

#   Start installatie van Windows 11
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume -ZTI

#   Start OOBE-deploy na installatie (verwijdert AppX, voegt NetFX toe, etc.)
Start-OOBEDeploy -PostAction 'Restart'
