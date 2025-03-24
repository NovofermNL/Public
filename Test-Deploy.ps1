<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11 en verwijdert vooraf AppX provisioned packages
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Stap 1: Installeer Windows 11 zonder extra drivers of updates
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

# Stap 2: Verwijder vooraf ongewenste AppX Provisioned Packages uit het geïnstalleerde image
$TargetPath = "C:\"
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
    Get-AppxProvisionedPackage -Path $TargetPath | Where-Object DisplayName -eq $app | ForEach-Object {
        Remove-AppxProvisionedPackage -Path $TargetPath -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

# Stap 3: Herstart naar OOBE
Restart-Computer
