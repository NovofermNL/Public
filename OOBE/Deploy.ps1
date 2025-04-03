###################################################################
########## Novoferm Nederland W11-24H2 OSDCloud Deploy.ps1 ########
###################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installeer OSD-module (indien buiten WinPE wordt dit overgeslagen)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Niet in WinPE – Install-Module OSD wordt overgeslagen"
} else {
    Write-Host -ForegroundColor Green "In WinPE – OSD-module wordt geladen"
    Install-Module -Name OSD -Force
}

# Importeer module
Import-Module OSD -Force

# Profielinstellingen
$CustomProfile = 'OSDDeploy'
$AddNetFX3     = $true
$AddRSAT       = $false
$Autopilot     = $false
$UpdateDrivers = $false
$UpdateWindows = $false
$SetEdition    = 'Enterprise'

# Appx-lijst (één centrale plek)
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

# Schrijf lijst naar JSON voor gebruik in OOBE-fase
$RemoveAppx | ConvertTo-Json | Out-File -FilePath "C:\Windows\Temp\RemoveAppx.json" -Encoding ascii -Force

# Start installatie van Windows 11 Enterprise NL-NL
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

# Genereer OOBE.cmd dat PostInstall.ps1 start
$OOBECMD = @'
@echo off
PowerShell -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Temp\PostInstall.ps1"
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

# Download PostInstall.ps1 naar C:\Windows\Temp
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NovofermNL/Public/main/OOBE/PostInstall.ps1" -OutFile "C:\Windows\Temp\PostInstall.ps1"

# Herstart systeem
Write-Host "Herstart systeem in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
