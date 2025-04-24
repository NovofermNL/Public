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

# Scriptinformatie (versie, naam)
$ScriptName = 'Novoferm Nederland Windows 11 Deployment'
$ScriptVersion = '25.01.22.1'
Write-Host -ForegroundColor Green "Scriptnaam: $ScriptName Versie: $ScriptVersion"
Add-Content -Path "$env:windir\Temp\OSDCloud.log" -Value "Start $ScriptName versie $ScriptVersion op $(Get-Date)"

# Informatie verzamelen over de huidige computer + OS voorkeuren definiëren
$Product = (Get-MyComputerProduct)
$Model = (Get-MyComputerModel)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
$OSVersion = 'Windows 11'
$OSReleaseID = '24H2'
$OSName = 'Windows 11 24H2 x64'
$OSEdition = 'Pro'
$OSActivation = 'Retail'
$OSLanguage = 'nl-nl'

# OSDCloud instellingen definiëren
$Global:MyOSDCloud = [ordered]@{
    Restart               = [bool]$False
    RecoveryPartition     = [bool]$true
    OEMActivation         = [bool]$True
    WindowsUpdate         = [bool]$true
    WindowsUpdateDrivers  = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone           = [bool]$true
    ClearDiskConfirm      = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB  = [bool]$true
    CheckSHA1             = [bool]$true
}

## Ophalen van bijpassende driverpack o.b.v. product, OS en release
$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID
if ($DriverPack) {
    $Global:MyOSDCloud.DriverPackName = $DriverPack.Name
}

## Specifieke driver update voor HP-systemen
if ($Manufacturer -match "HP") {
    Write-Host "HP-systeem gedetecteerd, starten met driver update via HP-script..."

    $tempPath = "$env:TEMP\Invoke-HPDriverUpdate.ps1"
    Invoke-RestMethod 'https://raw.githubusercontent.com/OSDeploy/OSD/master/Public/OSDCloudTS/Invoke-HPDriverUpdate.ps1' |
    Out-File -FilePath $tempPath -Encoding utf8 -Force
    Write-Host "Script opgeslagen naar: $tempPath"
    $arguments = "-ExecutionPolicy Bypass -NoLogo -File `\"$tempPath`\""
    Start-Process powershell.exe -ArgumentList $arguments -Wait -NoNewWindow
}

# HP-specifieke updates (BIOS / TPM / HPIA)
$UseHPIA = $true # Zet op $false voor snellere deployment zonder HPIA
if ($Manufacturer -match "HP") {
    if ($UseHPIA -and (Test-HPIASupport)) {
        Write-SectionHeader -Message "HP-apparaat gedetecteerd – HPIA, BIOS en TPM-updates worden ingeschakeld"

        # BIOS-settings toepassen
        iex (irm https://raw.githubusercontent.com/gwblok/garytown/master/OSD/CloudOSD/Manage-HPBiosSettings.ps1)
        Manage-HPBiosSettings -SetSettings

        try {
            if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope AllUsers -Force -ErrorAction Stop
            }
        }
        catch {
            Write-DarkGrayHost "FOUT: Install-PackageProvider mislukt: $($_.Exception.Message)"
        }

        try {
            if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
                Install-Module -Name PowerShellGet -Scope CurrentUser -AllowClobber -Force -SkipPublisherCheck -AcceptLicense -ErrorAction Stop
            }
        }
        catch {
            Write-DarkGrayHost "FOUT: Install-Module PowerShellGet mislukt: $($_.Exception.Message)"
        }

        try {
            if (-not (Get-Module -ListAvailable -Name HPCMSL)) {
                Install-Module -Name HPCMSL -Force -Scope AllUsers -SkipPublisherCheck -AcceptLicense -ErrorAction Stop
            }
        }
        catch {
            Write-DarkGrayHost "FOUT: Install-Module HPCMSL mislukt: $($_.Exception.Message)"
        }

        $Global:MyOSDCloud.HPTPMUpdate = [bool]$true
        $Global:MyOSDCloud.HPIAALL = [bool]$true
        $Global:MyOSDCloud.HPBIOSUpdate = [bool]$true
        $Global:MyOSDCloud.HPCMSLDriverPackLatest = [bool]$true
    }
}

# OSDCloud instellingen tonen
Write-SectionHeader -Message "OSDCloud-variabelen"
Write-Output $Global:MyOSDCloud | Out-File "$env:windir\Temp\OSDCloud.log" -Append

# Start OSDCloud installatie
Write-SectionHeader -Message "OSDCloud wordt gestart"
Write-Host "Start OSDCloud met: Naam = $OSName, Editie = $OSEdition, Activatie = $OSActivation, Taal = $OSLanguage"
Add-Content -Path "$env:windir\Temp\OSDCloud.log" -Value "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

# Na OSDCloud: aangepaste acties uitvoeren voor herstart
Write-SectionHeader -Message "OSDCloud-proces voltooid, aangepaste acties worden uitgevoerd vóór herstart"

# Systeem afsluiten na installatie
Write-SectionHeader -Message "Systeem wordt nu afgesloten..."
Add-Content -Path "$env:windir\Temp\OSDCloud.log" -Value "Systeem afsluiten om $(Get-Date)"
Restart-Computer -Force
