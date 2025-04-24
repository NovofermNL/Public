#region Initialisatie: Functies voor console-output (logging met opmaak)
function Write-DarkGrayDate {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String]
        $Message
    )
    $logPath = "$env:windir\Temp\OSDCloud.log"
    $logEntry = "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message"
    Add-Content -Path $logPath -Value $logEntry

    if ($Message) {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $Message"
    }
    else {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
    }
}

function Write-DarkGrayHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Message
    )
    $logPath = "$env:windir\Temp\OSDCloud.log"
    $logEntry = "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $Message"
    Add-Content -Path $logPath -Value $logEntry

    Write-Host -ForegroundColor DarkGray $Message
}

function Write-DarkGrayLine {
    [CmdletBinding()]
    param ()
    $logPath = "$env:windir\Temp\OSDCloud.log"
    Add-Content -Path $logPath -Value ('=' * 72)

    Write-Host -ForegroundColor DarkGray '========================================================================='
}

function Write-SectionHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Message
    )
    Write-DarkGrayLine
    Write-DarkGrayDate $Message
    Write-Host -ForegroundColor Cyan $Message

    $logPath = "$env:windir\Temp\OSDCloud.log"
    Add-Content -Path $logPath -Value "[HEADER] $Message"
}

function Write-SectionSuccess {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String]
        $Message = 'Gelukt!'
    )
    Write-DarkGrayDate $Message
    Write-Host -ForegroundColor Green $Message

    $logPath = "$env:windir\Temp\OSDCloud.log"
    Add-Content -Path $logPath -Value "[SUCCESS] $Message"
}
#endregion

$ScriptName = 'Novoferm Nederland Windows 11 Deployment'
$ScriptVersion = '25.01.22.1'
Write-Host -ForegroundColor Green "Scriptnaam: $ScriptName Versie: $ScriptVersion"
Add-Content -Path "$env:windir\Temp\OSDCloud.log" -Value "Start $ScriptName versie $ScriptVersion op $(Get-Date)"

$Product = (Get-MyComputerProduct)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$OSVersion = 'Windows 11'
$OSReleaseID = '24H2'
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Enterprise'
$OSActivation = 'Volume'
$OSLanguage = 'nl-nl'

$Global:MyOSDCloud = [ordered]@{
    Restart               = [bool]$False
    WindowsUpdate         = [bool]$false
    WindowsUpdateDrivers  = [bool]$true
    WindowsDefenderUpdate = [bool]$false
    SetTimeZone           = [bool]$false
    ClearDiskConfirm      = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB  = [bool]$true
}

$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID
if ($DriverPack) {
    $Global:MyOSDCloud.DriverPackName = $DriverPack.Name
}

if ($Manufacturer -match "HP") {
    Write-Host "HP-systeem gedetecteerd, starten met driver update via HP-script..."

    $tempPath = "$env:TEMP\Invoke-HPDriverUpdate.ps1"
    Invoke-RestMethod 'https://raw.githubusercontent.com/OSDeploy/OSD/master/Public/OSDCloudTS/Invoke-HPDriverUpdate.ps1' |
    Out-File -FilePath $tempPath -Encoding UTF8 -Force
    Write-Host "Script opgeslagen naar: $tempPath"

    $arguments = @(
        "-ExecutionPolicy", "Bypass",
        "-NoLogo",
        "-File", $tempPath
    )
    Start-Process powershell.exe -ArgumentList $arguments -Wait -NoNewWindow

    $UseHPIA = $true
    if ($UseHPIA -and (Test-HPIASupport)) {
        Write-SectionHeader -Message "HP-apparaat gedetecteerd – HPIA, BIOS en TPM-updates worden ingeschakeld"

        Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/gwblok/garytown/master/OSD/CloudOSD/Manage-HPBiosSettings.ps1')
        Manage-HPBiosSettings -SetSettings

        try {
            if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope AllUsers -Force -ErrorAction Stop
            }
        } catch {
            Write-DarkGrayHost "FOUT: Install-PackageProvider mislukt: $($_.Exception.Message)"
        }

        try {
            if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
                Install-Module -Name PowerShellGet -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck -AcceptLicense -ErrorAction Stop
            }
        } catch {
            Write-DarkGrayHost "FOUT: Install-Module PowerShellGet mislukt: $($_.Exception.Message)"
        }

        try {
            if (-not (Get-Module -ListAvailable -Name HPCMSL)) {
                Install-Module -Name HPCMSL -Force -Scope AllUsers -SkipPublisherCheck -AcceptLicense -ErrorAction Stop
            }
        } catch {
            Write-DarkGrayHost "FOUT: Install-Module HPCMSL mislukt: $($_.Exception.Message)"
        }

        $Global:MyOSDCloud.HPTPMUpdate = [bool]$true
        $Global:MyOSDCloud.HPIAALL = [bool]$true
        $Global:MyOSDCloud.HPBIOSUpdate = [bool]$true
        $Global:MyOSDCloud.HPCMSLDriverPackLatest = [bool]$true
    }
}

Write-SectionHeader -Message "OSDCloud-variabelen"
Write-Output $Global:MyOSDCloud | Out-File "$env:windir\Temp\OSDCloud.log" -Append

Write-SectionHeader -Message "OSDCloud wordt gestart"
Write-Host "Start OSDCloud met: Naam = $OSName, Editie = $OSEdition, Activatie = $OSActivation, Taal = $OSLanguage"
Add-Content -Path "$env:windir\Temp\OSDCloud.log" -Value "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"

Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Remove-AppX.ps1 -ErrorAction Stop | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OOBE.ps1 -ErrorAction Stop | Out-File -FilePath 'C:\Windows\Setup\scripts\OOBE.ps1' -Encoding ascii -Force
Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/main/Prod/start2.bin" -OutFile "C:\Windows\Setup\scripts\start2.bin" -ErrorAction Stop
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSDCloudModules/Copy-Start.ps1 -ErrorAction Stop | Out-File -FilePath 'C:\Windows\Setup\scripts\Copy-Start.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCleanUp.ps1 -ErrorAction Stop | Out-File -FilePath 'C:\Windows\Setup\scripts\OSDCleanUp.ps1' -Encoding ascii -Force

Copy-Item "X:\OSDCloud\Config\Run-Autopilot-Hash-Upload.cmd" -Destination "C:\Windows\System32\" -Force
Copy-Item "X:\OSDCloud\Config\Autopilot-Hash-Upload.ps1" -Destination "C:\Windows\System32\" -Force

$OOBECMD = @'
@echo off
REM Wait for Network 10 seconds
REM ping 127.0.0.1 -n 10 -w 1  >NUL 2>&1
REM Execute OOBE Tasks
start /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\OOBE.ps1
start /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Copy-Start.ps1
start /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Remove-AppX.ps1
start /wait powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\OSDCleanUp.ps1
exit /b 0
'@
$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding UTF8 -Force

Write-SectionHeader -Message "OSDCloud-proces voltooid, aangepaste acties worden uitgevoerd vóór herstart"
Write-SectionHeader -Message "Systeem wordt nu afgesloten..."
Add-Content -Path "$env:windir\Temp\OSDCloud.log" -Value "Systeem afsluiten om $(Get-Date)"
Restart-Computer -Force
