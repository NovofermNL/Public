<#
.SYNOPSIS
    Cleanup en voorbereiding na OSDCloud installatie
.DESCRIPTION
    Verwijdert ongewenste AppX applicaties en downloadt noodzakelijke bestanden voor verdere inrichting.
    Script is bedoeld om uitgevoerd te worden na Windows-installatie, vóór de eerste reboot.
.AUTHOR
    Novoferm Nederland BV
#>

# Zorg dat script vanuit C:\ draait
Set-Location C:\

# Forceer juiste ExecutionPolicy voor deze sessie
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# --- Logging Setup ---
$LogFolder = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD'
if (!(Test-Path -Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}
$LogFile = Join-Path $LogFolder "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-RemoveApps-Log.txt"
Start-Transcript -Path $LogFile -ErrorAction Ignore

Write-Host "=== Start Remove Appx Applications en Download Scripts ===" -ForegroundColor Cyan

# --- Applicaties verwijderen ---
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
)

Write-Host "Bezig met verwijderen van ongewenste AppX apps..." -ForegroundColor Yellow
Try {
    Invoke-Expression (Invoke-RestMethod 'https://functions.osdcloud.com')
    Remove-AppxOnline -Name $RemoveAppx
}
Catch {
    Write-Warning "Verwijderen van AppX packages is mislukt: $_"
}

# --- Download bestanden ---
Write-Host "Downloaden van start2.bin..." -ForegroundColor Yellow
Try {
    Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/main/Prod/start2.bin" -OutFile "C:\Windows\Setup\scripts\start2.bin" -UseBasicParsing
    Write-Host "start2.bin gedownload." -ForegroundColor Green
}
Catch {
    Write-Warning "Fout bij downloaden van start2.bin: $_"
}

Write-Host "Downloaden van Copy-Start.ps1..." -ForegroundColor Yellow
Try {
    Invoke-RestMethod -Uri "https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSDCloudModules/Copy-Start.ps1" | Out-File -FilePath "C:\Windows\Setup\scripts\Copy-Start.ps1" -Encoding ascii -Force
    Write-Host "Copy-Start.ps1 gedownload." -ForegroundColor Green
}
Catch {
    Write-Warning "Fout bij downloaden van Copy-Start.ps1: $_"
}

Write-Host "=== Script afgerond ===" -ForegroundColor Cyan

# Sluit logging af
Stop-Transcript
