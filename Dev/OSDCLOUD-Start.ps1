<#
Naam: Deploy.ps1
Datum: 01-04-2025
Beschrijving: Windows 11 24H2 Pro NL-NL via OSDCloud met RemoveAppx tijdens OOBE
Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Modules installeren
Install-Module OSD -Force
Import-Module OSD -Force

# Windows installeren
$OSDParams = @{
    OSVersion     = "Windows 11"
    OSBuild       = "24H2"
    OSEdition     = "Pro"
    OSLanguage    = "nl-nl"
    ZTI           = $true
    SkipAutopilot = $true
    SkipODT       = $true
}
Start-OSDCloud @OSDParams

# OOBEDeploy module installeren
Install-Module OOBEDeploy -Force
Import-Module OOBEDeploy -Force

# Appx verwijderen tijdens OOBE
$Params = @{
    Autopilot     = $false
    RemoveAppx    = "XboxGameOverlay","XboxSpeechToTextOverlay","Xbox.TCUI","XboxIdentityProvider",
                    "BingNews","GamingApp","GetHelp","Getstarted","Clipchamp","OfficeHub","OneNote",
                    "PowerAutomateDesktop","XboxGamingOverlay","WindowsMaps","ZuneVideo",
                    "CommunicationsApps","FeedbackHub","YourPhone","WebExperience","DevHome",
                    "Weather","People","Solitaire","WindowsAlarms","ZuneMusic","Todos",
                    "OutlookForWindows","549981C3F5F10","SpotifyMusic","Office.Desktop","Family","MSTeams"
    UpdateDrivers = $true
    UpdateWindows = $true
}
Start-OOBEDeploy @Params

# OOBEDeploy cmd-script aanmaken
$OOBECmd = @'
@echo off
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy
exit
'@
$OOBECmd | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Force

# Herstart naar OOBE
Write-Host -ForegroundColor Cyan "Herstart in 20 seconden voor OOBE-fase..."
Start-Sleep -Seconds 20
wpeutil reboot
