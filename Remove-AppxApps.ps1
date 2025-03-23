<#
Scriptnaam: Remove-AppxApps.ps1
Datum: 23-03-2025
Beschrijving: Verwijdert opgegeven AppX packages voor alle gebruikers tijdens OOBE.
Auteur: Novoferm Nederland BV
#>

$logDir = "C:\script-logging\Remove-AppxApps"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path "$logDir\log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

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
    Write-Host "`nVerwerken: $App" -ForegroundColor Yellow

    # Verwijder voor bestaande gebruikers
    Get-AppxPackage -AllUsers -Name $App | ForEach-Object {
        Write-Host " - Verwijderen package: $($_.Name)"
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }

    # Verwijder provisioned package
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like $App} | ForEach-Object {
        Write-Host " - Verwijderen provisioned package: $($_.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

Stop-Transcript
