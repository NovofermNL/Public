# Verwijder AppX apps én provisioned packages
$RemoveAppx = @(
    "Clipchamp.Clipchamp"
    "Microsoft.BingNews"
    "Microsoft.BingSearch"
    "Microsoft.BingWeather"
    "Microsoft.GamingApp"
    "Microsoft.GetHelp"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.OutlookForWindows"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.Todos"
    "Microsoft.Windows.DevHome"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.WindowsTerminal"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
)

$LogFile = "C:\Windows\Temp\Remove-AppX.log"

Function Write-Log {
    param($msg)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t$msg" | Out-File -Append -FilePath $LogFile
}

Write-Log "=== START AppX VERWIJDERING ==="

foreach ($App in $RemoveAppx) {
    Write-Log "Verwijderen: $App"

    # Verwijder voor huidige gebruiker
    $Installed = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*$App*" }
    foreach ($pkg in $Installed) {
        try {
            Write-Log "Verwijder geïnstalleerde app: $($pkg.Name)"
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        } catch {
            Write-Log "FOUT bij verwijderen van $($pkg.Name): $_"
        }
    }

    # Verwijder provisioned packages
    $Provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $App }
    foreach ($prov in $Provisioned) {
        try {
            Write-Log "Verwijder provisioned package: $($prov.DisplayName)"
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
        } catch {
            Write-Log "FOUT bij verwijderen van provisioned $($prov.DisplayName): $_"
        }
    }
}

Write-Log "=== KLAAR MET VERWIJDEREN ==="
