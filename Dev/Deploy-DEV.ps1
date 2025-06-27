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
$OSActivation = 'Retail'
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
#   OSDCLOUD Image met keuzemenu
#=======================================================================
$uselocalimage = $true
$OSDCloudDrive = Get-OSDCloudDrive
Write-Host -ForegroundColor Green -BackgroundColor Black "UseLocalImage is set to: $uselocalimage"

if ($uselocalimage -eq $true) {
    $wimFiles = Get-ChildItem -Path "$OSDCloudDrive\OSDCloud\OS\" -Filter "*.wim" -Recurse -File

    if ($wimFiles.Count -eq 0) {
        Write-Warning "Geen WIM-bestanden gevonden in $($OSDCloudDrive)\OSDCloud\OS\"
        $uselocalimage = $false
        return
    }

    Write-Host ""
    Write-Host "Beschikbare WIM-bestanden:" -ForegroundColor Cyan

    # Toon bestanden met index
    $index = 1
    $wimFiles | ForEach-Object {
        Write-Host "$index. $($_.FullName)" -ForegroundColor Yellow
        $index++
    }

    # Vraag om selectie
    $selection = Read-Host "`nTyp het nummer van het bestand dat je wilt gebruiken (1-$($wimFiles.Count))"

    # Valideer input
    if ($selection -as [int] -and $selection -ge 1 -and $selection -le $wimFiles.Count) {
        $ImageFileItem = $wimFiles[$selection - 1]
        $ImageFileName = $ImageFileItem.Name
        $ImageFileFullName = $ImageFileItem.FullName

        # Bevestiging
        Write-Host "`nGeselecteerde WIM: $ImageFileFullName" -ForegroundColor Green

        $confirm = Read-Host "Weet je zeker dat je dit bestand wilt gebruiken? (ja/nee)"
        if ($confirm -ne "ja") {
            Write-Warning "Installatie afgebroken door gebruiker."
            $uselocalimage = $false
            return
        }

        # Variabelen instellen
        $Global:MyOSDCloud.ImageFileItem = $ImageFileItem
        $Global:MyOSDCloud.ImageFileName = $ImageFileName
        $Global:MyOSDCloud.ImageFileFullName = $ImageFileFullName
        $Global:MyOSDCloud.OSImageIndex = 5  # Pas aan indien nodig

        Write-Host "`nWIM-bestand succesvol geselecteerd: $ImageFileName" -ForegroundColor Green
    }
    else {
        Write-Warning "Ongeldige selectie. Script afgebroken."
        $uselocalimage = $false
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

$DaRTScriptPath = "$env:TEMP\DaRT.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/osdcloudcline/OSDCloud/main/Extra%20Files/DaRT/DaRT.ps1" -OutFile $DaRTScriptPath
& $DaRTScriptPath


##### TEST #####
Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"

#Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Remove-AppX.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force
Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/main/Prod/Files/start2.bin" -OutFile "C:\Windows\Setup\scripts\start2.bin"
Invoke-RestMethod "https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCloud/Copy-Start.ps1" | Out-File -FilePath 'C:\Windows\Setup\scripts\Copy-Start.ps1' -Encoding ascii -Force
Invoke-RestMethod "https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCloud/Custom-Tweaks.ps1" | Out-File -FilePath 'C:\Windows\Setup\scripts\Custom-Tweaks.ps1' -Encoding ascii -Force
#Invoke-RestMethod "https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCloud/Create-ScheduledTask.ps1" | Out-File -FilePath 'C:\Windows\Setup\scripts\Create-ScheduledTask.ps1' -Encoding ascii -Force

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
::start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\Create-ScheduledTask.ps1" >> "%logfile%" 2>&1
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File "C:\Windows\Setup\scripts\Custom-Tweaks.ps1" >> "%logfile%" 2>&1

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
