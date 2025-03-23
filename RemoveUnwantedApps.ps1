<#
Naam: RemoveUnwantedApps.ps1
Datum: 23-03-2025
Beschrijving: Verwijdert ongewenste ingebouwde apps in Windows 11 24H2, incl. nieuwe Outlook en fallback-methodes
Novoferm Nederland BV
#>

# Log starten
$logPath = "C:\script-logging\RemoveUnwantedApps\log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
Start-Transcript -Path $logPath

# Lijst van Appx display names
$appxPackages = @(
    "Microsoft.OutlookForWindows",
    "Microsoft.549981C3F5F10", # Cortana
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
    "microsoft.windowscommunicationsapps", # Mail & Calendar
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

# Apps verwijderen (huidige en alle gebruikers)
foreach ($app in $appxPackages) {
    Write-Output ">> Probeer te verwijderen: $app"
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# Extra fallback: probeer alle provisioned packages met Name-vergelijking
foreach ($app in $appxPackages) {
    $provPkgs = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$app*" }
    foreach ($pkg in $provPkgs) {
        Write-Output ">> Fallback: Provisioned package verwijderen: $($pkg.PackageName)"
        Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction SilentlyContinue
    }
}

# Uitschakelen van Content Delivery Manager taken (die apps terugzetten)
$CDMTasks = @(
    "\Microsoft\Windows\ContentDeliveryManager\ContentDeliveryManager",
    "\Microsoft\Windows\ContentDeliveryManager\FeatureManagement"
)
foreach ($task in $CDMTasks) {
    try {
        Disable-ScheduledTask -TaskPath (Split-Path $task -Parent) -TaskName (Split-Path $task -Leaf) -ErrorAction Stop
        Write-Output ">> Taak uitgeschakeld: $task"
    } catch {
        Write-Output ">> Kan taak niet uitschakelen: $task"
    }
}

Write-Output "Verwijdering van ongewenste apps voltooid"
Stop-Transcript
