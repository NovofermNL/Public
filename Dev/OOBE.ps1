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

#Set OSDCloud Vars
 $Global:MyOSDCloud = [ordered]@{
     ClearDiskConfirm = [bool]$False
     }
 
 #write variables to console
 $Global:MyOSDCloud

#Variables bepalen welke windows versie wordt geinstalleerd. 
$OSVersion = 'Windows 11'
$OSReleaseID = '24H2'
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'nl-nl'

#Launch OSDCloud
Write-Host "Starting OSDCloud" -ForegroundColor Green
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

#================================================
#  [PostOS] Extra Scripts Downloaden (Copy-Start)
#================================================
Write-Host -ForegroundColor Green "Download Copy-Start.ps1 vanuit GitHub"
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/Copy-Start.ps1 | Out-File -FilePath 'C:\Windows\Setup\Scripts\Copy-Start.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCleanUp.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\OSDCleanUp.ps1' -Encoding ascii -Force

#================================================
#  [PostOS] OOBEDeploy Configuration
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "Autopilot": {
        "IsPresent": false
    },
    "AddNetFX3": {
        "IsPresent": true
    },
    "RemoveAppx": [
        "Clipchamp.Clipchamp",
        "Microsoft.BingNews",
        "Microsoft.BingSearch",
        "Microsoft.BingWeather",
        "Microsoft.GamingApp",
        "Microsoft.GetHelp",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.OutlookForWindows",
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.Todos",
        "Microsoft.Windows.DevHome",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.WindowsTerminal",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic"
    ],
    "UpdateDrivers": {
        "IsPresent": true
    },
    "UpdateWindows": {
        "IsPresent": true
    }
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE Configuration Staging
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
$AutopilotOOBEJson = @'
{
    "Assign": {
        "IsPresent": true
    },
    "GroupTag": "Office",
    "GroupTagOptions": [
        "Office",
        "Production"
    ],
    "Hidden": [
        "AssignedComputerName",
        "AssignedUser",
        "PostAction",
        "Assign",
        "AddToGroup"
    ],
    "PostAction": "Quit",
    "Run": "NetworkingWireless",
    "Docs": "https://google.com/",
    "Title": "Moelven Autopilot Registration"
}
'@
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#  [PostOS] AutopilotOOBE CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\OOBE.cmd"
$OOBECMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
Start /Wait PowerShell -NoL -C Import-Module OSD -Force
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Copy-Start.ps1
Start /Wait PowerShell -NoL -C Start-OOBEDeploy
Start /Wait PowerShell -NoL -C Start-AutopilotOOBE
'@
If (!(Test-Path "C:\Windows\Setup\Scripts")) {
    New-Item "C:\Windows\Setup\Scripts" -ItemType Directory -Force | Out-Null
}
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\OOBE.cmd' -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
# SetupComplete – wordt uitgevoerd vóór eerste login
$SetupComplete = @'
@echo off
:: Laatste opruimtaken vóór eerste login
powershell.exe -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\OSDCleanUp.ps1"
exit /b 0
'@

$SetupComplete | Out-File -FilePath 'C:\Windows\Setup\scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host "Restarting in 20 seconds!" -ForegroundColor Green
Start-Sleep -Seconds 20
wpeutil reboot
