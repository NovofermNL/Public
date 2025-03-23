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

# === START: Toevoegen van OOBEDeploy configuratie ===

Write-Host -ForegroundColor Cyan "OOBEDeploy configuratie aanmaken..."

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$OOBEDeployJson = @{
    OOBEDeploy = @{
        Scripts = @(
            "Invoke-WebPSScript 'https://raw.githubusercontent.com/NovofermNL/Public/refs/heads/main/RemoveUnwantedApps.ps1'"
        )
        Restart = $false
        LogPath = "C:\script-logging\RemoveUnwantedApps"
    }
}

$JsonPath = "$env:LocalAppData\Temp\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson | ConvertTo-Json -Depth 3 | Set-Content -Path $JsonPath -Encoding UTF8

Install-Module OOBEDeploy -Force
Start-OOBEDeploy

Write-Host -ForegroundColor Green "OOBEDeploy is geconfigureerd"

# === EIND: Toevoegen van OOBEDeploy configuratie ===

#Restart from WinPE
Write-Host  -ForegroundColor Cyan "Restart in 30 seconden"
Start-Sleep -Seconds 20
wpeutil reboot
