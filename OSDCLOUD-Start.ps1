<#
Naam: OSDCloud-Start.ps1
Datum: 23-03-2025
Beschrijving: Automatische installatie van Windows 11 via OSDCloud inclusief OOBEDeploy met RemoveAppx
Novoferm Nederland BV
#>

# Forceer TLS1.2 voor internetverkeer
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Zet execution policy tijdelijk op Bypass (alleen voor sessie)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Startbericht
Write-Host -ForegroundColor Cyan "Starten van OSDCloud..."
Start-Sleep -Seconds 3

# Modules installeren
Install-Module OSD -Force -AllowClobber -Scope AllUsers
Import-Module OSD -Force

# Parameters voor Windows-installatie
$OSDParams = @{
    OSBuild     = "24H2"
    OSEdition   = "Enterprise"
    OSLanguage  = "en-us"
    OSLicense   = "Retail"
    ZTI         = $true
    SkipAutopilot = $true
    SkipODT       = $true
}
Start-OSDCloud @OSDParams

# Post-OS: Installeer OOBEDeploy en configureer AppX-verwijdering
Install-Module OOBEDeploy -Force -AllowClobber -Scope AllUsers
Import-Module OOBEDeploy -Force

# OOBEDeploy uitvoeren met RemoveAppx lijst
$OOBEParams = @{
    Autopilot      = $false
    RemoveAppx     = @(
        "Clipchamp.Clipchamp",
        "Microsoft.ApplicationCompatibilityEnhancements",
        "Microsoft.AV1VideoExtension",
        "Microsoft.AVCEncoderVideoExtension",
        "Microsoft.BingNews",
        "Microsoft.BingSearch",
        "Microsoft.BingWeather",
        "Microsoft.DesktopAppInstaller",
        "Microsoft.GamingApp",
        "Microsoft.GetHelp",
        "Microsoft.HEIFImageExtension",
        "Microsoft.HEVCVideoExtension",
        "Microsoft.MicrosoftOfficeHub",                  # = OfficeHub
        "Microsoft.MicrosoftSolitaireCollection",        # = Solitaire
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.MPEG2VideoExtension",
        "Microsoft.OutlookForWindows",                   # = OutlookForWindows
        "Microsoft.Paint",
        "Microsoft.PowerAutomateDesktop",
        "Microsoft.RawImageExtension",
        "Microsoft.ScreenSketch",
        "Microsoft.SecHealthUI",
        "Microsoft.StorePurchaseApp",
        "Microsoft.Todos",
        "Microsoft.VP9VideoExtensions",
        "Microsoft.WebMediaExtensions",
        "Microsoft.WebpImageExtension",
        "Microsoft.Windows.DevHome",
        "Microsoft.Windows.Photos",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCalculator",
        "Microsoft.WindowsCamera",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsNotepad",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.WindowsStore",
        "Microsoft.WindowsTerminal",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "MicrosoftCorporationII.QuickAssist",
        "MicrosoftWindows.Client.WebExperience",
        "MicrosoftWindows.CrossDevice",
        "MSTeams"
    )
}
Start-OOBEDeploy @OOBEParams

# Reboot na afronden
Write-Host -ForegroundColor Cyan "Windows wordt opnieuw opgestart in 30 seconden..."
Start-Sleep -Seconds 30
wpeutil reboot
