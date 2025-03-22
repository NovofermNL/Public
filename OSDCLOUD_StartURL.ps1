Write-Host  -ForegroundColor Cyan "Starten van  OSDCloud"
Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Cyan "Resolutie aanpassen tot max 1600x"
    Set-DisRes 1600
}

#Make sure I have the latest OSD Content
Write-Host  -ForegroundColor Cyan "Update OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Cyan "Import OSD PowerShell Module"
Import-Module OSD -Force


#Start OSDCloud ZTI the RIGHT way
Write-Host  -ForegroundColor Cyan "Start OSDCloud met Parameters"
Start-OSDCloud -OSLanguage en-us -OSBuild 24H2 -OSEdition Enterprise -ZTI

#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restart in 30 seconden"
Start-Sleep -Seconds 20
wpeutil reboot
