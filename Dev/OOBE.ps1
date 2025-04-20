#=======================================================================
#  Novoferm Nederland W11-24H2 Deployment Script (volledig)
#=======================================================================

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

#=======================================================================
#  Define extra variabelen (Product, Manufacturer etc.)
#=======================================================================
$Product = (Get-MyComputerProduct)
$Model = (Get-MyComputerModel)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer

#=======================================================================
#   OSDCLOUD VARS
#=======================================================================
#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
    CheckSHA1 = [bool]$true
}

#=======================================================================
#   Driver Pack Logica
#=======================================================================
$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion 'Windows 11' -OSReleaseID '24H2'
if ($DriverPack) {
    $Global:MyOSDCloud.DriverPackName = $DriverPack.Name
}

$UseHPIA = $true
if ($Manufacturer -match "HP" -and $UseHPIA) {
    $Global:MyOSDCloud.HPTPMUpdate = $true
    $Global:MyOSDCloud.HPIAALL = $true
    $Global:MyOSDCloud.HPBIOSUpdate = $true
    $Global:MyOSDCloud.HPCMSLDriverPackLatest = $true
}

if ($Manufacturer -match "HP") {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope AllUsers -Force 
    Install-Module -Name PowerShellGet -Scope CurrentUser -AllowClobber -Force
    Install-Module -Name HPCMSL -Force -Scope AllUsers -SkipPublisherCheck
}

Write-Output $Global:MyOSDCloud

#=======================================================================
#   Start OSDCloud met parameters
#=======================================================================
$OSVersion = 'Windows 11'
$OSReleaseID = '24H2'
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'nl-nl'

Write-Host "Starting OSDCloud" -ForegroundColor Green
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

#=======================================================================
#   Scripts en Configuratie downloaden
#=======================================================================
Write-Host -ForegroundColor Green "Download OOBE scripts vanuit GitHub"
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Remove-AppX.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force
Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/main/Prod/start2.bin" -OutFile "C:\Windows\Setup\scripts\start2.bin"
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSDCloudModules/Copy-Start.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Copy-Start.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCleanUp.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\OSDCleanUp.ps1' -Encoding ascii -Force
Copy-Item "X:\OSDCloud\Config\Run-Autopilot-Hash-Upload.cmd" -Destination "C:\Windows\System32\" -Force
Copy-Item "X:\OSDCloud\Config\Autopilot-Hash-Upload.ps1" -Destination "C:\Windows\System32\" -Force

#=======================================================================
#   OOBE.cmd aanmaken
#=======================================================================
$OOBECMD = @'
@echo off
:: OOBE fase – verwijder standaard apps
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Remove-AppX.ps1
:: OOBE fase – Aanpassen Start Menu
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Copy-Start.ps1
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

#=======================================================================
#   SetupComplete.cmd aanmaken
#=======================================================================
$SetupComplete = @'
@echo off
:: Laatste opruimtaken vóór eerste login
powershell.exe -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\OSDCleanUp.ps1"
exit /b 0
'@
$SetupComplete | Out-File -FilePath 'C:\Windows\Setup\scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Herstart na 20 seconden
#=======================================================================
Write-Host -ForegroundColor Green "Herstart in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
