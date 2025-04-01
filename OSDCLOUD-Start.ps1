<#
Naam: OSDCloud-Start.ps1
Datum: 01-04-2025
Beschrijving: Automatische installatie van Windows 11 via OSDCloud inclusief OOBEDeploy met RemoveAppx via GitHub
Novoferm Nederland BV
#>

# Forceer TLS1.2 voor internetverkeer
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Zet execution policy tijdelijk op Bypass (alleen voor sessie)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Startbericht
Write-Host -ForegroundColor Cyan "Starten van OSDCloud..."
Start-Sleep -Seconds 3

# Modules installeren
Install-Module OSD -Force
Import-Module OSD -Force

# Parameters voor Windows-installatie
$OSDParams = @{
    OSBuild       = "24H2"
    OSEdition     = "Enterprise"
    OSLanguage    = "nl-nl"
    OSLicense     = "Retail"
    ZTI           = $true
    SkipAutopilot = $true
    SkipODT       = $true
}
Start-OSDCloud @OSDParams

# OOBEDeploy installeren en extern script uitvoeren via GitHub
Install-Module OOBEDeploy -Force 
Import-Module OOBEDeploy -Force
Start-OOBEDeploy -PostAction 'irm https://raw.githubusercontent.com/NovofermNL/Public/main/OOBE/Remove-Appx.ps1 | iex'

# Reboot na afronden
Write-Host -ForegroundColor Cyan "Windows wordt opnieuw opgestart in 30 seconden..."
Start-Sleep -Seconds 30
wpeutil reboot
