#=========================================
#   OSDCloud AutoPilot Deployment Script
#=========================================

# TLS 1.2 voor beveiligde verbindingen
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 

#=========================================
#   Start-OSDCloud na AutoPilot Upload
#=========================================
$Params = @{
    OSName = "Windows 11 24H2 x64"
    OSEdition = "Enterprise"
    OSLanguage = "nl-nl"
    OSActivation = "Volume"
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
