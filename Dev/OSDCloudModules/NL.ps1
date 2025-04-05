###################################################################
########## Novoferm Nederland W11-24h2 Deployment script ##########
###################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Buiten WinPE gedetecteerd – OSD-module wordt geïnstalleerd"
    Install-Module -Name OSD -Force
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module wordt overgeslagen"
}

try {
    Write-Host -ForegroundColor Green "Importeren van OSD PowerShell Module..."
    Import-Module -Name OSD -Force 
    Write-Host -ForegroundColor Green "OSD-module succesvol geïmporteerd"
}
catch {
    Write-Host -ForegroundColor Red "Fout bij het importeren van de OSD-module: $_"
    exit 1
}

# ---------------------------------------------------------------------------
# Profile OSD OSDDeploy
# ---------------------------------------------------------------------------

if ($CustomProfile -in 'OSD','OSDDeploy') {
  #  $AddNetFX3      = $true
  #  $AddRSAT        = $false
  #  $Autopilot      = $false
  #  $UpdateDrivers  = $false
  #  $UpdateWindows  = $false
    $RemoveAppx     = @(
        'Microsoft.549981C3F5F10',
        'Microsoft.BingWeather',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MixedReality.Portal',
        'Microsoft.Office.OneNote',
        'Microsoft.People',
        'Microsoft.SkypeApp',
        'Microsoft.Wallet',
        'Microsoft.WindowsCamera',
        'microsoft.windowscommunicationsapps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo'
    )

    # Schrijf lijst naar JSON-bestand dat later gebruikt wordt door OOBE.cmd
    $RemoveAppx | ConvertTo-Json | Out-File -FilePath "C:\Windows\Temp\RemoveAppx.json" -Encoding ascii -Force


Write-Host -ForegroundColor Cyan "Start installatie van Windows 11..."
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume

# Maak OOBE.cmd aan dat de Appx-lijst opnieuw inleest en gebruikt
Write-Host -ForegroundColor Green "Maak C:\Windows\System32\OOBE.cmd aan"

$OOBECMD = @'
Start /Wait PowerShell -NoLogo -Command "Set-ExecutionPolicy Bypass -Force"

$RemoveAppx = Get-Content -Path 'C:\Windows\Temp\RemoveAppx.json' | ConvertFrom-Json

foreach ($App in $RemoveAppx) {
    Write-Host "Verwijder Appx voor alle gebruikers: $App"
    Get-AppxPackage -AllUsers -Name $App | Remove-AppxPackage -ErrorAction SilentlyContinue

    Write-Host "Verwijder Appx Provisioned Package: $App"
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $App | ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

Start /Wait PowerShell -NoLogo -Command Start-OOBEDeploy -CustomProfile OSDDeploy
'@

$OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

# Herstart na 20 seconden
Write-Host -ForegroundColor Green "Herstart in 20 seconden..."
Start-Sleep -Seconds 20
wpeutil reboot
