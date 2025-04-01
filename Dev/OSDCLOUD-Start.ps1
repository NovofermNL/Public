<#
Naam: OSDCloud-Start.ps1
Datum: 01-04-2025
Beschrijving: Automatische installatie van Windows 11 via OSDCloud inclusief OOBEDeploy met RemoveAppx vanaf lokale schijf
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

# Script downloaden naar lokaal pad (C:\Windows\System32\OOBE)
$ScriptUrl  = "https://raw.githubusercontent.com/NovofermNL/Public/main/OOBE/Remove-Appx.ps1"
$ScriptPath = "C:\Windows\System32\OOBE\Remove-Appx.ps1"

if (-not (Test-Path "C:\Windows\System32\OOBE")) {
    New-Item -Path "C:\Windows\System32\OOBE" -ItemType Directory -Force | Out-Null
}

Invoke-WebRequest -Uri $ScriptUrl -OutFile $ScriptPath -UseBasicParsing
Write-Host "Remove-Appx.ps1 script opgeslagen op: $ScriptPath" -ForegroundColor Green

# OOBEDeploy installeren en script aanroepen vanaf lokaal pad
Install-Module OOBEDeploy -Force -AllowClobber -Scope AllUsers
Import-Module OOBEDeploy -Force

# Script uitvoeren NA OOBE via lokale PostAction
Start-OOBEDeploy -PostAction $ScriptPath

# Reboot na afronden
Write-Host -ForegroundColor Cyan "Windows wordt opnieuw opgestart in 30 seconden..."
Start-Sleep -Seconds 30
wpeutil reboot
