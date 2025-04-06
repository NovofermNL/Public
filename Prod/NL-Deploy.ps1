###################################################################
########## Novoferm Nederland W11-24h2 Deployment script ##########
##########                   Dominic Bruins              ##########
###################################################################

###### Enable TLS 1.2 #######

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

###### Insall en import OSD module #######

if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Buiten WinPE gedetecteerd – OSD-module wordt geinstalleerd"
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

###### Start Windows 11 Installatioe ######

Write-Host -ForegroundColor Cyan "Start installatie van Windows 11..."
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/RemoveAppx.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force
#Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/refs/heads/main/Prod/start2.bin" -OutFile "C:\Windows\Setup\scripts\start2.bin"

#invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSD-CleanUp.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\OSD-CleanUp.ps1' -Encoding ascii -Force

###### Maken van OOBE.cmd #######

$OOBECMD = @'
@echo off
:: OOBE fase – verwijder standaard apps
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Remove-AppX.ps1
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

####### Herstart na 20 seconden #######

Write-Host -ForegroundColor Green "Herstart in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
