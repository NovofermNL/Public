<#
Naam: OSDCloud-Start.ps1
Datum: 23-03-2025
Beschrijving: Automatische installatie van Windows 11 via OSDCloud inclusief configuratie van OOBEDeploy
Novoferm Nederland BV
#>

Write-Host -ForegroundColor Cyan "Starten van OSDCloud"
Start-Sleep -Seconds 5

# Resolutie aanpassen als het een virtuele machine is
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host -ForegroundColor Cyan "Resolutie aanpassen tot max 1600x"
    Set-DisRes 1600
}

# Update OSD module
Write-Host -ForegroundColor Cyan "Update OSD PowerShell Module"
Install-Module OSD -Force

Write-Host -ForegroundColor Cyan "Importeer OSD PowerShell Module"
Import-Module OSD -Force

# Start installatie van Windows 11 Enterprise 24H2 (Engels)
Write-Host -ForegroundColor Cyan "Start OSDCloud met Parameters"
Start-OSDCloud -OSLanguage en-us -OSBuild 24H2 -OSEdition Enterprise -ZTI

# === START: OOBEDeploy configuratie ===

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

Write-Host -ForegroundColor Green "OOBEDeploy is succesvol geconfigureerd"

# === EINDE: OOBEDeploy configuratie ===

# Wacht even zodat alles netjes wegschrijft, dan reboot
Write-Host -ForegroundColor Cyan "Herstart in 30 seconden..."
Start-Sleep -Seconds 30
wpeutil reboot
