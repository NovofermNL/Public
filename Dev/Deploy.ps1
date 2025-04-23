#region Initialisatie: Functies voor console-output (logging met opmaak)
function Write-DarkGrayDate {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String]
        $Message
    )
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
    Write-Host -ForegroundColor DarkGray $Message
}

function Write-DarkGrayLine {
    [CmdletBinding()]
    param ()
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
    Write-DarkGrayDate
    Write-Host -ForegroundColor Cyan $Message
}

function Write-SectionSuccess {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String]
        $Message = 'Gelukt!'
    )
    Write-DarkGrayDate
    Write-Host -ForegroundColor Green $Message
}
#endregion

# Scriptinformatie (versie, naam)
$ScriptName = 'win11.garytown.com'
$ScriptVersion = '25.01.22.1'
Write-Host -ForegroundColor Green "Scriptnaam: $ScriptName Versie: $ScriptVersion"

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

# Ophalen van bijpassende driverpack o.b.v. product, OS en release
$DriverPack = Get-OSDCloudDriverPack -Product $Product -OSVersion $OSVersion -OSReleaseID $OSReleaseID
if ($DriverPack) {
    $Global:MyOSDCloud.DriverPackName = $DriverPack.Name
}

# Specifieke driver update voor HP-systemen
if ($Manufacturer -match "HP") {
    Write-Host "HP-systeem gedetecteerd, starten met driver update via HP-script..."
    Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/OSDeploy/OSD/master/Public/OSDCloudTS/Invoke-HPDriverUpdate.ps1')
}

# HP-specifieke updates (BIOS / TPM / HPIA)
$UseHPIA = $true # Zet op $false voor snellere deployment zonder HPIA
if ($Manufacturer -match "HP") {
    if ($UseHPIA -and (Test-HPIASupport)) {
        Write-SectionHeader -Message "HP-apparaat gedetecteerd – HPIA, BIOS en TPM-updates worden ingeschakeld"

        # Activeer updates en functies
        $Global:MyOSDCloud.HPTPMUpdate = [bool]$true
        $Global:MyOSDCloud.HPIAALL = [bool]$true
        $Global:MyOSDCloud.HPBIOSUpdate = [bool]$true
        $Global:MyOSDCloud.HPCMSLDriverPackLatest = [bool]$true

        # BIOS-settings toepassen
        iex (irm https://raw.githubusercontent.com/gwblok/garytown/master/OSD/CloudOSD/Manage-HPBiosSettings.ps1)
        Manage-HPBiosSettings -SetSettings

        # Vereiste modules installeren
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope AllUsers -Force 
        Install-Module -Name PowerShellGet -Scope CurrentUser -AllowClobber -Force
        Install-Module -Name HPCMSL -Force -Scope AllUsers -SkipPublisherCheck
    }
}

# Lenovo BIOS-configuratie
if ($Manufacturer -match "Lenovo") {
    iex (irm https://raw.githubusercontent.com/gwblok/garytown/master/OSD/CloudOSD/Manage-LenovoBiosSettings.ps1)
    try {
        Manage-LenovoBIOSSettings -SetSettings
    }
    catch {
        # Indien een fout optreedt bij BIOS-configuratie, doe niets
    }
}

# OSDCloud instellingen tonen
Write-SectionHeader -Message "OSDCloud-variabelen"
Write-Output $Global:MyOSDCloud

# Start OSDCloud installatie
Write-SectionHeader -Message "OSDCloud wordt gestart"
Write-Host "Start OSDCloud met: Naam = $OSName, Editie = $OSEdition, Activatie = $OSActivation, Taal = $OSLanguage"
Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

# Na OSDCloud: aangepaste acties uitvoeren voor herstart
Write-SectionHeader -Message "OSDCloud-proces voltooid, aangepaste acties worden uitgevoerd vóór herstart"

<# CMTrace kopiëren naar lokale Windows installatie (handig voor logfiles openen)
if (Test-path -path "x:\windows\system32\cmtrace.exe") {
    copy-item "x:\windows\system32\cmtrace.exe" -Destination "C:\Windows\System\cmtrace.exe" -verbose
} #>

# Lenovo PowerShell modules kopiëren naar lokale schijf
if ($Manufacturer -match "Lenovo") {
    $PowerShellSavePath = 'C:\Program Files\WindowsPowerShell'
    Write-Host "Kopieer LSUClient module naar $PowerShellSavePath\Modules"
    Copy-PSModuleToFolder -Name LSUClient -Destination "$PowerShellSavePath\Modules"
    Write-Host "Kopieer Lenovo.Client.Scripting module naar $PowerShellSavePath\Modules"
    Copy-PSModuleToFolder -Name Lenovo.Client.Scripting -Destination "$PowerShellSavePath\Modules"
}

#restart-computer  # Uit te voeren indien gewenst na de installatie
