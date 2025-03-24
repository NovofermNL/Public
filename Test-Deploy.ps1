<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11 en verwijdert vooraf AppX provisioned packages
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   


# Stap 1: Installeer Windows 11
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

# Stap 2: Verwijder vooraf ongewenste AppX Provisioned Packages uit het geïnstalleerde image
$TargetPath = "C:\"
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
    Get-AppxProvisionedPackage -Path $TargetPath | Where-Object DisplayName -eq $app | ForEach-Object {
        Remove-AppxProvisionedPackage -Path $TargetPath -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

# Stap 3: Herstart naar OOBE
Restart-Computer
