<#
Scriptnaam: Deploy.ps1
Beschrijving: Volledige automatische installatie via OSDCloud met AppX-verwijdering vóór OOBE
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Logging
$LogPath = "C:\script-logging\Remove-Appx\"
New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
Start-Transcript -Path "$LogPath\Remove-Appx.log" -Append

Write-Host "Start OSDCloud installatie..."

# Stap 1: Installeer Windows
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume -DriverPack Dell -UpdateDrivers -UpdateWindows

# Stap 2: Verwijder AppX Provisioned Packages vóór OOBE
$apps = @(
    'Clipchamp.Clipchamp',
    'Microsoft.549981C3F5F10',
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.GamingApp',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.People',
    'Microsoft.Todos',
    'Microsoft.WindowsAlarms',
    'microsoft.windowscommunicationsapps',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsMaps',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.YourPhone',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'Microsoft.OutlookForWindows' # Nieuwe Outlook
)

foreach ($app in $apps) {
    $provisioned = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app
    foreach ($pkg in $provisioned) {
        Write-Host "Verwijderen: $($pkg.DisplayName) ($($pkg.PackageName))"
        Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction SilentlyContinue
    }
}

Stop-Transcript

# Optioneel: reboot na installatie en opruimen
Restart-Computer
