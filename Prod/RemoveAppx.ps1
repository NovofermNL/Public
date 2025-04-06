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
    "Microsoft.WindowsTerminal"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "MicrosoftWindows.Client.WebExperience"
    "MSTeams"
)

foreach ($App in $RemoveAppx) {
    Write-Host "Verwijderen: $App"
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $App } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
