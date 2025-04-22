###################################################################
########## Novoferm Nederland W11-24h2 Deployment script ##########
###################################################################

# TLS 1.2 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installeer de OSD-module (alleen buiten WinPE)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Buiten WinPE gedetecteerd – OSD-module wordt geïnstalleerd"
    Install-Module -Name OSD -Force
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module wordt overgeslagen"
}

# Importeer de OSD-module
try {
    Write-Host -ForegroundColor Green "Importeren van OSD PowerShell Module..."
    Import-Module -Name OSD -Force 
    Write-Host -ForegroundColor Green "OSD-module succesvol geïmporteerd"
}
catch {
    Write-Host -ForegroundColor Red "Fout bij het importeren van de OSD-module: $_"
    exit 1
}
#  ---------------------------------------------------------------------------
#  Profile OSD OSDDeploy
#  ---------------------------------------------------------------------------

$OSName = 'Windows 11 23H2 x64'
$OSEdition = 'Pro'
$OSActivation = 'Retail'
$OSLanguage = 'en-us'

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

Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage


# Maak OOBE.cmd voor automatische taken tijdens OOBE-fase
Write-Host -ForegroundColor Green "Maak C:\Windows\System32\OOBE.cmd aan"

$OOBECMD = @'
Start /Wait PowerShell -NoL -C PowerShell Set-ExecutionPolicy ByPass -Force
::Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
:: Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
::Start /Wait PowerShell -NoL -C Import-Module AutopilotOOBE -Force
::Start /Wait PowerShell -NoLogo -Command Import-Module OSD -Force
Start /Wait PowerShell -NoLogo -Command Start-OOBEDeploy -Customprofile OSDDeploy
'@

$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

# Reboot vanuit WinPE
Write-Host -ForegroundColor Green "Herstart in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
