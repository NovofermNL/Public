<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11 en verwijdert vooraf AppX provisioned packages
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

#   PreOS - Set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#   Install and Import OSD Module (met WinPE-check)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Updating OSD PowerShell Module (buiten WinPE)"
    Install-Module OSD -Force 
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module OSD wordt overgeslagen"
}
Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#   Installeer Windows 11
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

#   Verwijder vooraf ongewenste AppX Provisioned Packages uit het geïnstalleerde image
$TargetPath = "C:\"
$logFile = "C:\script-logging\Deploy\remove-appx.log"
New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null

$apps = @(
    "Microsoft.549981C3F5F10"                # Cortana
    "Microsoft.BingWeather"
    "Microsoft.BingSearch"                   # BingSearch extensie
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"                   # 'Aan de slag'
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.MixedReality.Portal"
    "Microsoft.MSPaint"
    "Microsoft.Office.OneNote"
    "Microsoft.OneDrive"
    "Microsoft.People"
    "Microsoft.PowerAutomateDesktop"         # Power Automate Desktop
    "Microsoft.SkypeApp"
    "Microsoft.Todos"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsCamera"
    "microsoft.windowscommunicationsapps"    # Mail & Agenda
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "MicrosoftTeams"                         # Teams (Store app)
    "Microsoft.OutlookForWindows"            # New Outlook
)

foreach ($app in $apps) {
    $matchedPackages = Get-AppxProvisionedPackage -Path $TargetPath | Where-Object DisplayName -eq $app

    foreach ($package in $matchedPackages) {
        $msg = "Verwijderen: $($package.DisplayName) - $($package.PackageName)"
        Write-Host -ForegroundColor Cyan $msg
        $msg | Out-File -Append -FilePath $logFile
        Remove-AppxProvisionedPackage -Path $TargetPath -PackageName $package.PackageName -ErrorAction SilentlyContinue
    }

    if (-not $matchedPackages) {
        $msg = "Niet gevonden: $app"
        Write-Host -ForegroundColor DarkGray $msg
        $msg | Out-File -Append -FilePath $logFile
    }
}

#   Herstart naar OOBE
Restart-Computer
