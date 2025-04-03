###################################################################
########## Novoferm Nederland W11-24h2 Deployment script ##########
###################################################################

# TLS 1.2 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installeer de OSD-module (alleen buiten WinPE)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Buiten WinPE gedetecteerd – OSD-module wordt geïnstalleerd"
    Install-Module -Name OSD -Force -Scope CurrentUser
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module wordt overgeslagen"
}

# Importeer de OSD-module
try {
    Write-Host -ForegroundColor Green "Importeren van OSD PowerShell Module..."
    Import-Module -Name OSD -Force -ErrorAction Stop
    Write-Host -ForegroundColor Green "OSD-module succesvol geïmporteerd"
}
catch {
    Write-Host -ForegroundColor Red "Fout bij het importeren van de OSD-module: $_"
    exit 1
}

# Start installatie van Windows 11 via OSDCloud
Write-Host -ForegroundColor Cyan "Start installatie van Windows 11..."
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

# Maak OOBE.cmd voor automatische taken tijdens OOBE-fase
Write-Host -ForegroundColor Green "Maak C:\Windows\System32\OOBE.cmd aan"

$OOBECMD = @'
Start /Wait PowerShell -NoL -C PowerShell Set-ExecutionPolicy ByPass -Force
::Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
::Start /Wait PowerShell -NoL -C Import-Module AutopilotOOBE -Force
Start /Wait PowerShell -NoL -C Import-Module OSD -Force
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Start-OOBE-Deploy.ps1
'@

$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

# Reboot vanuit WinPE
Write-Host -ForegroundColor Green "Herstart in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
