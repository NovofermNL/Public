<#
Scriptnaam: PostInstall.ps1
Beschrijving: Verwijdert AppX packages en installeert .NET Framework 3.5 na installatie van Windows
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

#   AppX Provisioned Packages verwijderen
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

#   AppX Online Packages (per user) verwijderen
$RemoveAppx = @(
    "CommunicationsApps",
    "OfficeHub",
    "People",
    "Skype",
    "Solitaire",
    "Xbox",
    "ZuneMusic",
    "ZuneVideo",
    "OutlookForWindows"
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

#   .NET Framework 3.5 installeren (en gerelateerde NetFX-capabilities)
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

#   Herstart na afronding
Restart-Computer
