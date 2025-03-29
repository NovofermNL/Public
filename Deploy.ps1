<#
Scriptnaam: Deploy.ps1
Beschrijving: Installeert Windows 11 en verwijdert vooraf AppX provisioned packages
Datum: 24-03-2025
Organisatie: Novoferm Nederland BV
#>

#   PreOS - Set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#   Install and Import OSD Module (met WinPE-check)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Updating OSD PowerShell Module (buiten WinPE)"
    Install-Module OSD -Force 
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module OSD wordt overgeslagen"
}
Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#   Installeer Windows 11
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

#   Verwijder vooraf ongewenste AppX Provisioned Packages uit het geïnstalleerde image
$TargetPath = "C:\"
$apps = @(
    "Microsoft.549981C3F5F10",              
    "Microsoft.BingWeather",
    "Microsoft.BingSearch",                  
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",                
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.MSPaint",
    "Microsoft.Office.OneNote",
    "Microsoft.OneDrive",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",      
    "Microsoft.SkypeApp",
    "Microsoft.Todos",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCamera",
    "microsoft.windowscommunicationsapps",   
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "MicrosoftTeams"                      
)

foreach ($app in $apps) {
    Get-AppxProvisionedPackage -Path $TargetPath | Where-Object DisplayName -eq $app | ForEach-Object {
        Remove-AppxProvisionedPackage -Path $TargetPath -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

#   Herstart naar OOBE
Restart-Computer
