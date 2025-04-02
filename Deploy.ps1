Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"
Start-Sleep -Seconds 5

Start-OSDCloud -OSVersion 'Windows 11' -OSBuild 24H2 -OSEdition Pro -OSLanguage nl-nl -OSLicense Retail -ZTI

# Restart from WinPE
Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBETasks.CMD"

$OOBETasksCMD = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
Set Path=%PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
:: Start /Wait PowerShell -NoL -C Start-AutopilotOOBE
Start /Wait PowerShell -NoL -C Start-OOBEDeploy -AddNetFX3 -RemoveAppx -SetEdition Enterprise -verbose
Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@

$OOBETasksCMD | Out-File -FilePath 'C:\Windows\System32\OOBETasks.CMD' -Encoding ascii -Force

Write-Host -ForegroundColor Green "Restarting in 20 seconds..."
Start-Sleep -Seconds 20

wpeutil reboot
