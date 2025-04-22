<#
    Scriptnaam: Update-Windows.ps1
    Beschrijving: Installeert automatisch de laatste Windows-updates incl. CUs
    Bron: Novoferm Nederland BV
    Datum: 22-04-2025
#>

# Forceer TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Logging
$LogPath = "C:\Windows\Temp\"
$LogFile = Join-Path $LogPath "WindowsUpdate.log"

# Zorg dat logmap bestaat
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

# Begin logging
Start-Transcript -Path $LogFile -Append

Write-Host "=== Update-Windows.ps1 gestart op $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss') ==="

# Zorg dat NuGet beschikbaar is
Write-Host "Controle op NuGet-provider..."
Install-PackageProvider -Name NuGet -Force -Scope AllUsers

# Installeer PSWindowsUpdate
Write-Host "Installeren van PSWindowsUpdate-module..."
Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers

# Zet execution policy tijdelijk open
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Updates installeren
Write-Host "Importeren van PSWindowsUpdate-module..."
Import-Module PSWindowsUpdate

Write-Host "Starten met downloaden en installeren van updates..."
Get-WindowsUpdate -AcceptAll -Install -AutoReboot

Write-Host "=== Update-Windows.ps1 voltooid op $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss') ==="

# Stop logging
Stop-Transcript
