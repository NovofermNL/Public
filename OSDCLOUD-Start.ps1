<#
Naam: OSDCloud-Start.ps1
Datum: 23-03-2025
Beschrijving: Automatische installatie van Windows 11 via OSDCloud inclusief OOBEDeploy met RemoveAppx
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
Install-Module OSD -Force -AllowClobber -Scope AllUsers
Import-Module OSD -Force

# Parameters voor Windows-installatie
$OSDParams = @{
    OSBuild     = "24H2"
    OSEdition   = "Enterprise"
    OSLanguage  = "en-us"
    OSLicense   = "Retail"
    ZTI         = $true
    SkipAutopilot = $true
    SkipODT       = $true
}
Start-OSDCloud @OSDParams

# Post-OS: Installeer OOBEDeploy en configureer AppX-verwijdering
Install-Module OOBEDeploy -Force -AllowClobber -Scope AllUsers
Import-Module OOBEDeploy -Force

# OOBEDeploy uitvoeren met RemoveAppx lijst
$OOBEParams = @{
    Autopilot      = $false
    RemoveAppx     = @(
        "CommunicationsApps",
        "OfficeHub",
        "People",
        "Skype",
        "Solitaire",
        "Xbox",
        "ZuneMusic",
        "ZuneVideo",
        "OutlookForWindows",
        "YourPhone",
        "MicrosoftWindows.Client.WebExperience"
    )
    UpdateDrivers  = $true
    UpdateWindows  = $true
}
Start-OOBEDeploy @OOBEParams

# Reboot na afronden
Write-Host -ForegroundColor Cyan "Windows wordt opnieuw opgestart in 30 seconden..."
Start-Sleep -Seconds 30
wpeutil reboot
