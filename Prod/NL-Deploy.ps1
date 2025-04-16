
###################################################################
########## Novoferm Nederland W11-24h2 Deployment script ##########
###################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Buiten WinPE gedetecteerd – OSD-module wordt geïnstalleerd"
    Install-Module -Name OSD -Force
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module wordt overgeslagen"
}

try {
    Write-Host -ForegroundColor Green "Importeren van OSD PowerShell Module..."
    Import-Module -Name OSD -Force 
    Write-Host -ForegroundColor Green "OSD-module succesvol geïmporteerd"
}
catch {
    Write-Host -ForegroundColor Red "Fout bij het importeren van de OSD-module: $_"
    exit 1
}

Write-Host -ForegroundColor Cyan "Start installatie van Windows 11..."
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume -zti

Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"

Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Remove-AppX.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force
Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/main/Prod/start2.bin" -OutFile "C:\Windows\Setup\scripts\start2.bin"
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSDCloudModules/Copy-Start.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Copy-Start.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCleanUp.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\OSDCleanUp.ps1' -Encoding ascii -Force
Copy-Item "X:\OSDCloud\Config\Run-Autopilot-Hash-Upload.cmd" -Destination "C:\Windows\System32\" -Force
Copy-Item "X:\OSDCloud\Config\Autopilot-Hash-Upload.ps1" -Destination "C:\Windows\System32\" -Force
#invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSD-CleanUp.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\OSD-CleanUp.ps1' -Encoding ascii -Force

$OOBECMD = @'
@echo off
:: OOBE fase – verwijder standaard apps
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Remove-AppX.ps1
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Copy-Start.ps1
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\OSDCleanUp.ps1
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

# Herstart na 20 seconden
Write-Host -ForegroundColor Green "Herstart in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
