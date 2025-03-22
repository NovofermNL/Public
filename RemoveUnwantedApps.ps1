# Save this script as RemoveUnwantedApps.ps1

# Define a list of apps to remove
$appxPackages = @(
    "Clipchamp.Clipchamp",
    "Microsoft.549981C3F5F10",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Todos",
    "Microsoft.WindowsAlarms",
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsStore",
    "Microsoft.WindowsTerminal",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "MicrosoftCorporationII.QuickAssist",
    "MicrosoftWindows.Client.WebExperience"
)


# Remove for current user
foreach ($appxPackage in $appxPackages) {
    Get-AppxPackage -Name $appxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# Remove provisioned package for new users
foreach ($appxPackage in $appxPackages) {
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $appxPackage | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Write-Output "Unwanted apps have been removed."
