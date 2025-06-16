$ScriptName = 'Installeren Windows 11'
$ScriptVersion = '24.7.4.4'
Write-Host -ForegroundColor Green "$ScriptName $ScriptVersion"

#=======================================================================
#   OSDCLOUD Definitions
#=======================================================================
$Product = (Get-MyComputerProduct)
$Model = (Get-MyComputerModel)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$OSVersion = 'Windows 11'
$OSReleaseID = '24H2'
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Pro'
$OSActivation = 'Volume'
$OSLanguage = 'nl-nl'

#=======================================================================
#   OSDCLOUD VARS
#=======================================================================
$Global:MyOSDCloud = [ordered]@{
    Restart               = [bool]$false
    RecoveryPartition     = [bool]$false
    OEMActivation         = [bool]$true
    WindowsUpdate         = [bool]$true
    MSCatalogFirmware     = [bool]$true
    WindowsUpdateDrivers  = [bool]$true
    WindowsDefenderUpdate = [bool]$false
    SetTimeZone           = [bool]$false
    SkipClearDisk         = [bool]$false
    ClearDiskConfirm      = [bool]$false
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB  = [bool]$true
    CheckSHA1             = [bool]$true
    ZTI                   = [bool]$true
}

#=======================================================================
#   LOCAL DRIVE LETTERS
#=======================================================================
function Get-WinPEDrive {
    $WinPEDrive = (Get-WmiObject Win32_LogicalDisk | Where-Object { $_.VolumeName -eq 'WINPE' }).DeviceID
    write-host "Current WINPE drive is: $WinPEDrive"
    return $WinPEDrive
}
function Get-OSDCloudDrive {
    $OSDCloudDrive = (Get-WmiObject Win32_LogicalDisk | Where-Object { $_.VolumeName -eq 'OSDCloudUSB' }).DeviceID
    write-host "Current OSDCLOUD Drive is: $OSDCloudDrive"
    return $OSDCloudDrive
}
#=======================================================================
#   OSDCLOUD Image
#=======================================================================
$uselocalimage = $true
$Windowsversion = "$OSVersion $OSReleaseID"
$OSDCloudDrive = Get-OSDCloudDrive
Write-Host -ForegroundColor Green -BackgroundColor Black "UseLocalImage is set to: $uselocalimage"
#dynamically find the latest version based on the variables set in the beginning of the script
if ($uselocalimage -eq $true) {
    # Find the latest month WIM file
    $months = @("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "okt", "nov", "dec")
    $wimlist = Get-ChildItem -Path "$OSDCloudDrive\OSDCloud\OS\" -Filter "*.wim" -Recurse
    write-host "Available wimfiles: $wimlist"
    $wimFiles = Get-ChildItem -Path "$OSDCloudDrive\OSDCloud\OS\" -Filter "*.wim" -Recurse | Where-Object { $_.Name -match "$Windowsversion" }
    $latestMonth = $months | Where-Object { $wimFiles.Name -match $_ } | Select-Object -Last 1

    if ($latestMonth) {
        $WIMName = "$Windowsversion - $latestMonth.wim"
        Write-Host -ForegroundColor Green -BackgroundColor Black "Latest WIM file found: $WIMName This WimFile will be used for the installation"
    }
    else {
        Write-Host -ForegroundColor Red -BackgroundColor Black "No WIM files found for $Windowsversion using esd as backup."
        Write-Host -ForegroundColor Red -BackgroundColor Black "PLEASE ADD THE WIM FILE TO THE OSDCLOUD USB DRIVE TO SURPRESS THIS MESSAGE"
        $uselocalimage = $false
        Start-Sleep -Seconds 10
    }
}

if ($uselocalimage -eq $true) {
    $ImageFileItem = Find-OSDCloudFile -Name $WIMName  -Path "\OSDCloud\OS\"
    if ($ImageFileItem) {
        write-host "Variable uselocalimage is set to true. The installer will try to find and use the wim file called: $WIMName"
        $ImageFileItem = $ImageFileItem | Where-Object { $_.FullName -notlike "C*" } | Where-Object { $_.FullName -notlike "X*" } | Select-Object -First 1
        if ($ImageFileItem) {
            $ImageFileName = Split-Path -Path $ImageFileItem.FullName -Leaf
            $ImageFileFullName = $ImageFileItem.FullName
            
            $Global:MyOSDCloud.ImageFileItem = $ImageFileItem
            $Global:MyOSDCloud.ImageFileName = $ImageFileName
            $Global:MyOSDCloud.ImageFileFullName = $ImageFileFullName
            $Global:MyOSDCloud.OSImageIndex = 5
        }
    }
}

#=======================================================================
#   Specific Driver Pack
#=======================================================================
$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID

# Forceer gebruik van TLS 1.2 voor veilig downloaden van modules
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Controleer of de machine van HP is
if ($Manufacturer -match "HP") {
    Write-Host "HP hardware gedetecteerd. Start met installatie van benodigde modules..."

    # Schakel Publisher Signature Validation tijdelijk uit
    $originalPolicy = Get-ExecutionPolicy
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    # Installeer NuGet Package Provider
    try {
        Write-Host "NuGet Package Provider installeren..."
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope AllUsers -Force -ErrorAction Stop
            Write-Host "NuGet Package Provider succesvol geïnstalleerd."
        }
        else {
            Write-Host "NuGet Package Provider is al geïnstalleerd."
        }
    }
    catch {
        Write-Warning "NuGet Package Provider installatie mislukt: $_"
    }

    # Installeer PowerShellGet module
    try {
        Write-Host "PowerShellGet module installeren..."
        if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
            Install-Module -Name PowerShellGet -Scope CurrentUser -AllowClobber -Force -ErrorAction Stop
            Write-Host "PowerShellGet module succesvol geïnstalleerd."
        }
        else {
            Write-Host "PowerShellGet module is al geïnstalleerd."
        }
    }
    catch {
        Write-Warning "PowerShellGet installatie mislukt: $_"
    }

    # Installeer HPCMSL module
    try {
        Write-Host "HPCMSL module installeren..."
        Install-Module -Name HPCMSL -Force -Scope AllUsers -SkipPublisherCheck -AcceptLicense -ErrorAction Stop
        Write-Host "HPCMSL module succesvol geïnstalleerd."
    }
    catch {
        Write-Warning "HPCMSL module installatie mislukt: $_"
    }

    # Herstel oorspronkelijke Execution Policy
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy $originalPolicy -Force

    Write-Host "Installatie van HP-specifieke modules voltooid."
}
else {
    Write-Host "Geen HP hardware gedetecteerd. Het script wordt beëindigd."
}
#=======================================================================
#   Write OSDCloud VARS to Console
#=======================================================================
Write-Output $Global:MyOSDCloud

#=======================================================================
#   Update OSDCloud modules
#=======================================================================
$ModulePath = (Get-ChildItem -Path "$($Env:ProgramFiles)\WindowsPowerShell\Modules\osd" | Where-Object { $_.Attributes -match "Directory" } | select -Last 1).fullname
import-module "$ModulePath\OSD.psd1" -Force

#=======================================================================
#   Start OSDCloud installation
#=======================================================================
Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"

Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

write-host "OSDCloud Process Complete, Running Custom Actions From Script Before Reboot" -ForegroundColor Green

##### TEST #####
Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"

#Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Remove-AppX.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force
Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/main/Prod/Files/start2.bin" -OutFile "C:\Windows\Setup\scripts\start2.bin"
Invoke-RestMethod "https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCloud/Copy-Start.ps1" | Out-File -FilePath 'C:\Windows\Setup\scripts\Copy-Start.ps1' -Encoding ascii -Force
Invoke-RestMethod "https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCloud/Configure-OutlookAutodiscover-OnPrem.ps1" | Out-File -FilePath 'C:\Windows\Setup\scripts\onfigure-OutlookAutodiscover-OnPrem.ps1' -Encoding ascii -Force
Invoke-RestMethod "https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCloud/Create-ScheduledTask.ps1" | Out-File -FilePath 'C:\Windows\Setup\scripts\Create-ScheduledTask.ps1' -Encoding ascii -Force

#invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSD-CleanUp.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\OSD-CleanUp.ps1' -Encoding ascii -Force

$OOBECMD = @'
@echo off
:: OOBE fase verwijder standaard apps en wijzig start-menu
::start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Remove-AppX.ps1
::start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Copy-Start.ps1
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

$SetupComplete = @'
@echo off
:: Setup logging
for /f %%a in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd-HHmmss')"') do set logname=%%a-Cleanup-Script.log
set logfolder=C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD
set logfile=%logfolder%\%logname%

:: Zorg dat logmap bestaat
if not exist "%logfolder%" mkdir "%logfolder%"

:: Zet drive naar C: 
C:

reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v SearchOnTaskbarMode /t REG_DWORD /d 0 /f
reg add "HKEY_USERS\.DEFAULT\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Policies\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f

:: Cleanup logs en folders
echo === Start Cleanup %date% %time% === >> "%logfile%"
if exist "C:\Windows\Temp" (
    copy /Y "C:\Windows\Temp\*.log" "%logfolder%" >> "%logfile%" 2>&1
)

if exist "C:\Temp" (
    copy /Y "C:\Temp\*.log" "%logfolder%" >> "%logfile%" 2>&1
)

if exist "C:\OSDCloud\Logs" (
    copy /Y "C:\OSDCloud\Logs\*.log" "%logfolder%" >> "%logfile%" 2>&1
)

if exist "C:\ProgramData\OSDeploy" (
    copy /Y "C:\ProgramData\OSDeploy\*.log" "%logfolder%" >> "%logfile%" 2>&1
)

for %%D in (
    "C:\OSDCloud"
    "C:\Drivers"
    "C:\Intel"
    "C:\ProgramData\OSDeploy"
) do (
    if exist %%D (
        echo Removing folder %%D >> "%logfile%"
        rmdir /S /Q %%D >> "%logfile%" 2>&1
    )
)

:: Start copy-start script
echo Starten van Copy-Start.ps1 >> "%logfile%"
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\Copy-Start.ps1" >> "%logfile%" 2>&1
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\Create-ScheduledTask.ps1" >> "%logfile%" 2>&1

echo === SetupComplete Afgerond %date% %time% === >> "%logfile%"

exit /b 0
'@

# Schrijf het SetupComplete script weg
$SetupComplete | Out-File -FilePath 'C:\Windows\Setup\scripts\SetupComplete.cmd' -Encoding ascii -Force


# Herstart na 20 seconden
Write-Host -ForegroundColor Green "Herstart in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot

#   Herstart naar OOBE
Restart-Computer

###### EIDNE TEST ######


#=======================================================================
#   REBOOT DEVICE
#=======================================================================
#Write-Host  -ForegroundColor Green "Restarting now!"
#Restart-Computer -Force
