<#
Scriptnaam: Remove-AppxApps.ps1
Datum: 23-03-2025
Beschrijving: Verwijdert opgegeven AppX packages voor alle gebruikers tijdens OOBE.
Auteur: Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$scriptName = "Remove-AppxApps"
$logDir = "C:\script-logging\$scriptName"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = "$logDir\log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $logFile

try {
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
        Write-Output "Verwerken: $App"

        # Verwijder voor bestaande gebruikers
        $existingPackages = Get-AppxPackage -AllUsers -Name $App
        if ($existingPackages) {
            foreach ($pkg in $existingPackages) {
                Write-Output " - Verwijderen package: $($pkg.Name)"
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
            }
        }

        # Verwijder provisioned package
        $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App }
        if ($provisioned) {
            foreach ($prov in $provisioned) {
                Write-Output " - Verwijderen provisioned package: $($prov.DisplayName)"
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
            }
        }
    }
}
catch {
    Write-Output "Fout opgetreden tijdens verwerking: $_"
}
finally {
    Stop-Transcript
}
