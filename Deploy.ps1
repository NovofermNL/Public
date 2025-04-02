<#
Scriptnaam: Deploy.ps1 
Datum: 03-04-2025
Beschrijving: Windows 11 24H2 installatie zonder
Auteur: Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Alleen OSD-module installeren als we niet in WinPE zijn
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Buiten WinPE – OSD-module wordt geïnstalleerd"
    Install-Module -Name OSD -Force -Scope CurrentUser
}

# Importeer de OSD-module
Import-Module -Name OSD -Force

# Start installatie ZONDER -ZTI zodat OOBE uitgevoerd wordt
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

# Schrijf OOBE.cmd die tijdens OOBE-fase onze deployment aanroept
$OOBECMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Start-OOBE-Deploy.ps1 -CustomProfile Custom
'@

# OOBE.cmd opslaan op juiste locatie zodat deze uitgevoerd wordt
$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

# Herstart uit WinPE zodat Windows installatie verdergaat
Write-Host -ForegroundColor Green "Herstart in 15 seconden..."
Start-Sleep -Seconds 15
wpeutil reboot
