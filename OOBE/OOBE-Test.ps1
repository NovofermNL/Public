<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11 en verwijdert vooraf AppX provisioned packages + user-based AppX packages, en voegt .NET Framework 3.5 toe
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

$apps = @(
    "Microsoft.549981C3F5F10"
    "Microsoft.BingWeather"
    "Microsoft.BingSearch"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.MixedReality.Portal"
    "Microsoft.MSPaint"
    "Microsoft.Office.OneNote"
    "Microsoft.OneDrive"
    "Microsoft.People"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.SkypeApp"
    "Microsoft.Todos"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsCamera"
    "microsoft.windowscommunicationsapps"
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
    "MicrosoftTeams"
    "Microsoft.OutlookForWindows"
)

Write-Host -ForegroundColor Yellow "Start verwijderen van AppX Provisioned Packages..."
foreach ($app in $apps) {
    $matchedPackages = Get-AppxProvisionedPackage -Path $TargetPath | Where-Object DisplayName -eq $app

    foreach ($package in $matchedPackages) {
        Write-Host -ForegroundColor Cyan "Verwijderen: $($package.DisplayName) - $($package.PackageName)"
        Remove-AppxProvisionedPackage -Path $TargetPath -PackageName $package.PackageName -ErrorAction SilentlyContinue
    }

    if (-not $matchedPackages) {
        Write-Host -ForegroundColor DarkGray "Niet gevonden: $app"
    }
}

#   Verwijder ook user-based AppX packages via Remove-AppxOnline (post-install)
$RemoveAppx = @(
    "CommunicationsApps",
    "OfficeHub",
    "People",
    "Skype",
    "Solitaire",
    "Xbox",
    "ZuneMusic",
    "ZuneVideo",
    "OutlookForWindows"  # Nieuwe Outlook (Store-versie)
)

Write-Host -ForegroundColor Yellow "Start verwijderen van AppX Online (user-based)..."
foreach ($Item in $RemoveAppx) {
    try {
        Write-Host -ForegroundColor Magenta "Remove-AppxOnline -Name $Item"
        Remove-AppxOnline -Name $Item -ErrorAction Stop
    } catch {
        Write-Warning "Fout bij verwijderen van $Item via Remove-AppxOnline: $_"
    }
}

#   Installeer .NET Framework 3.5 (en gerelateerde capabilities via OSD Get-MyWindowsCapability)
Write-Host -ForegroundColor Yellow "Controleren op NetFX-gerelateerde Windows Capabilities..."

$AddWindowsCapability = Get-MyWindowsCapability -Match 'NetFX' -Detail

foreach ($Item in $AddWindowsCapability) {
    if ($Item.State -eq 'Installed') {
        Write-Host -ForegroundColor DarkGray "$($Item.DisplayName)"
    }
    else {
        Write-Host -ForegroundColor DarkCyan "Installeren: $($Item.DisplayName)"
        try {
            $Item | Add-WindowsCapability -Online -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "Fout bij installeren van $($Item.DisplayName): $_"
        }
    }
}

#   Herstart naar OOBE
Restart-Computer
