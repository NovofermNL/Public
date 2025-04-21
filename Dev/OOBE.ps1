#================================================
#   OSDCloud Task Sequence - Novoferm W11 24H2 NL
#================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#================================================
#   PreOS - Install and Import OSD Module
#================================================
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Buiten WinPE gedetecteerd – OSD-module wordt geïnstalleerd"
    Install-Module -Name OSD -Force
}
else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module wordt overgeslagen"
}

Import-Module OSD -Force

#================================================
#   [OS] Start-OSDCloud with Params
#================================================
$Params = @{
    OSBuild     = "24H2"
    OSEdition   = "Enterprise"
    OSLanguage  = "nl-nl"
    OSLicense   = "Volume"
    SkipAutopilot = $true
    SkipODT     = $true
}
Start-OSDCloud @Params

#================================================
#   PostOS - OOBEDeploy Configuration
#================================================
$OOBEDeployJson = @'
{
    "AddNetFX3":  { "IsPresent": true },
    "Autopilot":  { "IsPresent": false },
    "RemoveAppx":  [
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
    "UpdateDrivers": { "IsPresent": true },
    "UpdateWindows": { "IsPresent": true }
}
'@

$OOBEPath = "C:\ProgramData\OSDeploy"
if (!(Test-Path $OOBEPath)) {
    New-Item -Path $OOBEPath -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "$OOBEPath\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#================================================
#   PostOS - Download Scripts
#================================================
$ScriptPath = "C:\Windows\Setup\scripts"
if (!(Test-Path $ScriptPath)) { New-Item -ItemType Directory -Path $ScriptPath -Force | Out-Null }

Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/main/Prod/start2.bin" -OutFile "$ScriptPath\start2.bin"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NovofermNL/Public/main/Update-HPDrivers.ps1" -OutFile "$ScriptPath\Update-HPDrivers.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSDCloudModules/Copy-Start.ps1" -OutFile "$ScriptPath\Copy-Start.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCleanUp.ps1" -OutFile "$ScriptPath\OSDCleanUp.ps1"
Copy-Item "X:\OSDCloud\Config\Manage-HP-Biossettings.ps1" -Destination "$ScriptPath\Manage-HP-BIOS-Settings.ps1" -Force

#================================================
#   PostOS - Set OOBEDeploy CMD
#================================================
$OOBECMD = @'
@echo off

:: Set the PowerShell Execution Policy
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force

:: Set BIOS Settings if HP Device
PowerShell -NoL -Command "if ((Get-CimInstance -Class Win32_ComputerSystem).Manufacturer -like '*HP*') { & 'C:\Windows\Setup\scripts\Manage-HP-BIOS-Settings.ps1' -SetSettings }"

:: Copy Custom Start Menu
start /Wait PowerShell -NoL -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\Copy-Start.ps1"

:: Update HP Drivers if HP Device
PowerShell -NoL -Command "if ((Get-CimInstance -Class Win32_ComputerSystem).Manufacturer -like '*HP*') { & 'C:\Windows\Setup\scripts\Update-HPDrivers.ps1' }"

:: Start OOBEDeploy
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy

exit
'@
$OOBECMD | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Force

#================================================
#   PostOS - SetupComplete
#================================================
$SetupComplete = @'
@echo off
::Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Preview'" -Wait
PowerShell.exe -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\OSDCleanUp.ps1"
exit /b 0
'@
$SetupComplete | Out-File -FilePath "C:\Windows\Setup\scripts\SetupComplete.cmd" -Encoding ascii -Force

#================================================
#   PostOS - Restart Computer
#================================================
Write-Host -ForegroundColor Green "Herstart in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
