<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11, .NET Framework 3.5 en verwijdert AppX provisioned packages via extern script
Datum: 31-03-2025
Organisatie: Novoferm Nederland BV
#>

# TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install and Import OSD Module (skip in WinPE)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Updating OSD PowerShell Module (buiten WinPE)"
    Install-Module OSD -Force
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module OSD wordt overgeslagen"
}

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

# Start installatie van Windows 11
Write-Host -ForegroundColor Cyan "Installatie van Windows 11 wordt gestart..."
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

# Installeer .NET Framework 3.5
Write-Host -ForegroundColor Cyan "Installeren van .NET Framework 3.5..."
try {
    Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart
    Write-Host -ForegroundColor Green ".NET Framework 3.5 succesvol geïnstalleerd."
} catch {
    Write-Host -ForegroundColor Red "Fout bij installatie van .NET Framework 3.5: $_"
}

# Verwijder AppX provisioned packages via extern script
Write-Host -ForegroundColor Cyan "Start verwijderen van AppX apps via extern script..."

$scriptUrl = "https://raw.githubusercontent.com/NovofermNL/Public/main/Remove-AppxApps.ps1"
$localScriptPath = "$env:TEMP\Remove-AppxApps.ps1"

try {
    Invoke-WebRequest -Uri $scriptUrl -OutFile $localScriptPath
    if (Test-Path $localScriptPath) {
        Write-Host -ForegroundColor Green "Extern AppX-script succesvol gedownload."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$localScriptPath`"" -Wait
        Write-Host -ForegroundColor Green "AppX-verwijdering voltooid."
    } else {
        throw "Download mislukt: bestand niet gevonden op lokale pad."
    }
} catch {
    Write-Host -ForegroundColor Red "Fout bij downloaden of uitvoeren van het externe AppX-script: $_"
}

# Herstart naar OOBE
Write-Host -ForegroundColor Cyan "Herstart naar OOBE..."
Restart-Computer
