# Verwijder standaard ingebouwde apps uit het Windows image (provisioned packages)

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

foreach ($App in $RemoveAppx) {
    Write-Log "Zoeken naar app: $App"
    $Package = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $App }
    
    if ($Package) {
        Write-Log "Gevonden: $($Package.DisplayName) - Verwijderen..."
        $Package | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Write-Log "Verwijderd: $App"
    } else {
        Write-Log "Niet gevonden: $App"
    }
}
