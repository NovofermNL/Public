<## Eerst zeker weten dat de OSD-module geïmporteerd is
Import-Module OSD -Force

# Jouw bestaande array
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
    "Microsoft.YourPhonee"
    "Microsoft.ZuneMusic"
    "MicrosoftWindows.Client.WebExperience"
    "MSTeams"
)

# Voer de functie uit met de volledige lijst
Remove-AppxOnline -Name $RemoveAppx
#>
Get-AppxPackage -AllUsers Clipchamp.Clipchamp | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.549981C3F5F10 | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.BingNews | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.BingSearch | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.BingWeather | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.GamingApp | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.GetHelp | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.Getstarted | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.MicrosoftOfficeHub | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.MicrosoftSolitaireCollection | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.MicrosoftStickyNotes | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.People | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.PowerAutomateDesktop | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.ScreenSketch | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.Todos | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.WindowsAlarms | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers microsoft.windowscommunicationsapps | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers microsoft.windowscommunicationsapp | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.WindowsFeedbackHub | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.WindowsMaps | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.WindowsSoundRecorder | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.Xbox.TCUI | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.XboxGameOverlay | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.XboxIdentityProvider | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.XboxSpeechToTextOverlay | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.YourPhone | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.ZuneMusic | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers Microsoft.ZuneVideo | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers MicrosoftCorporationII.QuickAssist | Remove-AppxPackage -AllUsers
Get-AppxPackage -AllUsers MSTeams | Remove-AppxPackage -AllUsers
