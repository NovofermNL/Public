
# Opruimen van OSD Deployment folders
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Cleanup-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\OSDeploy\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute OSD Cloud Cleanup Script" -ForegroundColor Green

# Kopieeren  OOBEDeploy en AutopilotOOBE Logs
Get-ChildItem 'C:\Windows\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\OSDeploy\' -Force

# Kopieëren OSDCloud Logs
If (Test-Path -Path 'C:\OSDCloud\Logs') {
    Move-Item 'C:\OSDCloud\Logs\*.*' -Destination 'C:\ProgramData\OSDeploy\' -Force

# Opruimen Folders
If (Test-Path -Path 'C:\OSDCloud') { Remove-Item -Path 'C:\OSDCloud' -Recurse -Force }
If (Test-Path -Path 'C:\Drivers') { Remove-Item 'C:\Drivers' -Recurse -Force }
If (Test-Path -Path 'C:\Intel') { Remove-Item 'C:\Intel' -Recurse -Force }
#If (Test-Path -Path 'C:\ProgramData\OSDeploy') { Remove-Item 'C:\ProgramData\OSDeploy' -Recurse -Force }


Stop-Transcript
