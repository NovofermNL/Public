#================================================
#   OSDCloud Build Sequence
#   WARNING: Will wipe hard drive without prompt!!
#   Windows 11 24H2 Pro nl-nl Volume
#   Deploys OS
#   Updates OS
#   Removes AppX Packages from OS
#   No Office Deployment Tool
#   Creates post deployment scripts for Autopilot
#================================================

#   PreOS - Set VM Display Resolution
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host -ForegroundColor Cyan "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#   PreOS - Set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#   Install and Import OSD Module (met WinPE-check)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Updating OSD PowerShell Module (buiten WinPE)"
    Install-Module OSD -Force -AllowClobber -SkipPublisherCheck
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module OSD wordt overgeslagen"
}
Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#   Waarschuwing voor dataverlies
Write-Host "`nDISCLAIMER: - Going further will erase all data on your disk!`n" -ForegroundColor Red

#================================================
#   Start-OSDCloud met NL-NL instellingen
#================================================
$Params = @{
    OSName        = "Windows 11 24H2 x64"
    OSEdition     = "Pro"
    OSLanguage    = "nl-nl"
    OSLicense     = "Volume"
    SkipAutopilot = $false
    SkipODT       = $true
    ZTI           = $true
}
Start-OSDCloud @Params

#================================================
#   WinPE PostOS - Verwijder AppX pakketten
#================================================
Start-Transcript -Path "C:\script-logging\Remove-AppxApps\log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

$AppList = @(
    "Microsoft.Xbox*",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.SkypeApp",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.People",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MixedReality.Portal",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Todos",
    "Microsoft.OneConnect",
    "Microsoft.OutlookForWindows"
)

foreach ($App in $AppList) {
    Write-Host "Verwijderen van: $App" -ForegroundColor Yellow
    Get-AppxPackage -AllUsers -Name $App | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like $App} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Stop-Transcript

#================================================
#   WinPE PostOS - OOBEDeploy met updates
#================================================
Start-OOBEDeploy -UpdateDrivers -UpdateWindows

#================================================
#   WinPE PostOS - Set OOBEDeploy CMD.ps1
#================================================
$SetCommand = @'
@echo off
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts
start PowerShell -NoL -W Mi
Start /Wait PowerShell -NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/durrante/OSDCloud/main/ScriptPad/Set-EmbeddedBIOSProductKey.ps1
start "Install-Module OSD" /wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy
exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Force

#================================================
#   WinPE PostOS - Set AutopilotOOBE CMD.ps1
#================================================
$SetCommand = @'
@echo off
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts
start PowerShell -NoL -W Mi
start "Install-Module AutopilotOOBE" /wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
start "Start-AutopilotOOBE" PowerShell -NoL -C Start-AutopilotOOBE
exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\Autopilot.cmd" -Encoding ascii -Force

wpeutil reboot
