<#
Scriptnaam: Remove-AppxApps.ps1
Datum: 23-03-2025
Beschrijving: Verwijdert opgegeven AppX packages voor alle gebruikers (inclusief provisioning) tijdens OOBE.
Auteur: Novoferm Nederland BV
#>

# Logging
$logDir = "C:\script-logging\Remove-AppxApps"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path "$logDir\log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Lijst met AppX packages (wildcards toegestaan)
$AppList = @(
    "Microsoft.Xbox*",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.SkypeApp",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.People",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MixedReality.Portal",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Todos",
    "Microsoft.OneConnect",
    "Microsoft.OutlookForWindows"  
)

foreach ($App in $AppList) {
    Write-Host "`nBezig met verwijderen van: $App" -ForegroundColor Yellow

    # Verwijder geïnstalleerde appx packages (voor alle users)
    Get-AppxPackage -AllUsers -Name $App | ForEach-Object {
        Write-Host " - Verwijderen package: $($_.Name)"
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }

    # Verwijder provisioned packages (voor toekomstige gebruikers)
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like $App} | ForEach-Object {
        Write-Host " - Verwijderen provisioned package: $($_.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

Stop-Transcript
