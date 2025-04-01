<#
Naam: Deploy.ps1
Datum: 01-04-2025
Beschrijving: OSDCloud-installatie inclusief automatische Appx-verwijdering via OSDeploy.OOBEDeploy.json
Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "=== Start OSDCloud Setup ===" -ForegroundColor Cyan

# --- Stap 1: Installeer OSD-module ---
Install-Module OSD -Force
Import-Module OSD -Force

# --- Stap 2: Start Windows 11 installatie ---
$OSDParams = @{
    OSVersion    = "Windows 11"
    OSBuild      = "24H2"
    OSEdition    = "Pro"
    OSLanguage   = "nl-nl"
    ZTI          = $true
    Firmware     = $true
}
Start-OSDCloud @OSDParams

# --- Stap 3: Maak OSDeploy.OOBEDeploy.json aan ---
$OOBEDeployJson = @'
{
  "Autopilot": {
    "IsPresent": false
  },
  "RemoveAppx": [
    "Microsoft.549981C3F5F10",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MixedReality.Portal",
    "Microsoft.Office.OneNote",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    "Microsoft.WindowsCamera",
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
  ],
  "UpdateDrivers": {
    "IsPresent": true
  },
  "UpdateWindows": {
    "IsPresent": true
  },
  "PostAction": "Quit"
}
'@

$OOBEDeployPath = "C:\ProgramData\OSDeploy"
if (-not (Test-Path $OOBEDeployPath)) {
    New-Item -Path $OOBEDeployPath -ItemType Directory -Force | Out-Null
}

$OOBEDeployJson | Out-File -FilePath "$OOBEDeployPath\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force
Write-Host "OOBEDeploy-configuratiebestand aangemaakt op: $OOBEDeployPath" -ForegroundColor Green

# --- Stap 4: Reboot om OOBE fase te starten ---
Write-Host -ForegroundColor Cyan "Windows wordt opnieuw opgestart in 30 seconden..."
Start-Sleep -Seconds 30
wpeutil reboot
