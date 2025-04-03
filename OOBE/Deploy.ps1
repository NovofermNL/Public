###################################################################
########## Novoferm Nederland W11-24H2 OSDCloud Deploy.ps1 ########
###################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Alleen in WinPE: OSD-module laden
if ($env:SystemDrive -eq "X:") {
    Write-Host -ForegroundColor Green "In WinPE – OSD-module wordt geïnstalleerd"
    Install-Module -Name OSD -Force
    Import-Module -Name OSD -Force
}

# Profielinstellingen
$CustomProfile = 'OSDDeploy'
$AddNetFX3     = $true
$AddRSAT       = $true
$Autopilot     = $false
$UpdateDrivers = $false
$UpdateWindows = $false
$SetEdition    = 'Enterprise'

# Appx-lijst
$RemoveAppx = @(
    'Microsoft.549981C3F5F10',
    'Microsoft.BingWeather',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.Microsoft3DViewer',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MixedReality.Portal',
    'Microsoft.Office.OneNote',
    'Microsoft.People',
    'Microsoft.SkypeApp',
    'Microsoft.Wallet',
    'Microsoft.WindowsCamera',
    'microsoft.windowscommunicationsapps',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsMaps',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxApp',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.YourPhone',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo'
)

# Schrijf lijst naar JSON-bestand
$RemoveAppx | ConvertTo-Json | Out-File -FilePath 'C:\Windows\Temp\RemoveAppx.json' -Encoding ascii -Force

# Start installatie van Windows 11 Enterprise NL-NL
Write-Host -ForegroundColor Cyan "Start installatie van Windows 11..."
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

# Download Remove-AppX.ps1 naar Setup-scriptlocatie
Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Remove-AppX.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force

# Genereer OOBE.cmd
$OOBECMD = @'
@echo off
:: Execute Appx-verwijdering
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\Remove-AppX.ps1"

:: Debug sessie in SYSTEM-context (optioneel)
:: start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass

exit
'@

$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

# Reboot uit WinPE
Write-Host "Herstart systeem in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
