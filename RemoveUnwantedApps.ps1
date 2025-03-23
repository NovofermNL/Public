# Save this script as RemoveUnwantedApps.ps1

# Define a list of apps to remove
$appxPackages = @(
    "Clipchamp.Clipchamp",
    "Microsoft.549981C3F5F10", # Cortana
    "Microsoft.BingNews",
    "microsoft.outlookforwindows",
    "Microsoft.BingWeather",
    "Microsoft.GamingApp", # Xbox app
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.OneConnect", # Your Phone
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.Todos",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCamera",
    "microsoft.windowscommunicationsapps", # Mail and Calendar
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
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
    "MicrosoftWindows.Client.WebExperience",
    "MicrosoftTeams", # Teams
    "SpotifyAB.SpotifyMusic",
    "AdobeSystemsIncorporated.AdobePhotoshopExpress",
    "king.com.CandyCrushSaga",
    "king.com.CandyCrushSodaSaga",
    "king.com.CandyCrushFriends",
    "Playtika.CaesarsSlotsFreeCasino",
    "Playtika.SlotomaniaFreeSlots",
    "Duolingo-LearnLanguagesforFree",
    "PandoraMediaInc",
    "Wunderlist",
    "Flipboard.Flipboard",
    "TwitterInc.Twitter",
    "Facebook.Facebook",
    "Facebook.Instagram",
    "Facebook.Messenger",
    "NetflixInc.Netflix",
    "TikTok.TikTok"
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
