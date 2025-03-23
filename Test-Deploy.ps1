<#
Scriptnaam: Deploy-OSDCloud.ps1
Datum: 23-03-2025
Beschrijving: Start automatisch de installatie van Windows 11 24H2 (nl-nl, volume), met driver updates en OOBE-script via GitHub.
Auteur: Novoferm Nederland BV
#>

Write-Host ">>> [OSDCloud] Installatie wordt gestart..." -ForegroundColor Cyan

# Configureer OSDCloud image (automatisch)
$OSDCloudConfig = @{
    OSVersion       = "Windows 11"
    OSEdition       = "Pro"
    OSBuild         = "24H2"
    OSLanguage      = "nl-nl"
    OSLicense       = "Volume"
    ZTI             = $true
    Restart         = $true
    DriverPack      = $true
}

Start-OSDCloud @OSDCloudConfig

# Script dat tijdens OOBE uitgevoerd wordt (download van GitHub)
$scriptUrl = "https://raw.githubusercontent.com/<jouwGitHubRepo>/main/Remove-AppxApps.ps1"
$scriptPath = "C:\MyScripts\Remove-AppxApps.ps1"

Write-Host ">>> Downloaden van Remove-AppxApps.ps1 vanaf GitHub..."
New-Item -Path "C:\MyScripts" -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath

# Start OOBE fase met AppX verwijdering
Start-OOBEDeploy -UpdateDrivers -UpdateWindows -Script $scriptPath
