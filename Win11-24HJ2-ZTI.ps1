#=========================================
#   OSDCloud AutoPilot Deployment Script
#=========================================

# TLS 1.2 voor beveiligde verbindingen
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 

# Device Tag Selectie
$tags = @("NL-ICT", "NL-Buitendienst", "NL-Marketing")
$deviceTag = $tags | Out-GridView -Title "Selecteer Device Tag voor AutoPilot" -PassThru

if ($null -eq $deviceTag) {
    Write-Output "Geen selectie gemaakt. Script wordt afgesloten."
    exit 0
}

# Logging
$logPath = "X:\OSDCloud\AutoPilotUpload.log"
Write-Output "Device Tag geselecteerd: $deviceTag" | Out-File -FilePath $logPath -Append

# Controleer of Get-WindowsAutoPilotInfo aanwezig is
$AutoPilotScript = "X:\OSDCloud\Scripts\Get-WindowsAutoPilotInfo.ps1"

if (!(Test-Path $AutoPilotScript)) {
    Write-Output "Fout: Get-WindowsAutoPilotInfo.ps1 niet gevonden op $AutoPilotScript" | Out-File -FilePath $logPath -Append
    exit 1
}

# AutoPilot Upload uitvoeren vanuit lokaal script
Write-Host -ForegroundColor Green "Uploading AutoPilot hash naar Intune..."
powershell.exe -ExecutionPolicy Bypass -File $AutoPilotScript -Online -GroupTag $deviceTag

# Controle of upload gelukt is
if ($LASTEXITCODE -eq 0) {
    Write-Output "AutoPilot upload succesvol! Start nu Windows installatie..." | Out-File -FilePath $logPath -Append
} else {
    Write-Output "Fout bij upload naar Intune AutoPilot. Script wordt gestopt." | Out-File -FilePath $logPath -Append
    exit 1
}

#=========================================
#   Start-OSDCloud na AutoPilot Upload
#=========================================
$Params = @{
    OSName = "Windows 10 24H2 x64"
    OSEdition = "Enterprise"
    OSLanguage = "nl-nl"
    OSActivation = "Retail"
    ZTI = $true  # Zero-Touch Install
}
Start-OSDCloud @Params

#=========================================
#   Post-Install AutoPilot OOBE
#=========================================
Install-Module AutopilotOOBE -Force -AllowClobber -SkipPublisherCheck
Import-Module AutopilotOOBE -Force

$Params = @{
    Title = 'Autopilot Registration'
    GroupTagOptions = $deviceTag
    Hidden = 'AddToGroup','AssignedComputerName','AssignedUser','PostAction'
    Assign = $true
    PostAction = 'Restart'
    Run = 'PowerShell'
    Disabled = 'Assign'
}
AutopilotOOBE @Params

#=========================================
#   Post-Install Cleanup & Reboot
#=========================================
Write-Host -ForegroundColor Cyan "Windows Installatie en AutoPilot Configuratie voltooid. Het systeem wordt herstart."
shutdown.exe /r /t 30
