<#
Scriptnaam: Enable-HighPerformance.ps1
Beschrijving: Dupliceert en activeert het High Performance energieplan
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "`n[INFO] High Performance plan wordt toegevoegd en geactiveerd..." -ForegroundColor Cyan

# GUID van standaard High Performance plan
$originalGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

# Stap 1: Dupliceren
$cloneOutput = powercfg -duplicatescheme $originalGuid

# Stap 2: GUID ophalen
if ($cloneOutput -match 'GUID: ([a-f0-9\-]+)') {
    $newGuid = $matches[1]
    Write-Host "[INFO] Gekloond energieplan GUID: $newGuid" -ForegroundColor Green

    # Stap 3: Hernoemen (optioneel)
    powercfg -changename $newGuid "High Performance (Persistent)"

    # Stap 4: Activeren
    powercfg /setactive $newGuid
    Write-Host "[INFO] High Performance plan is nu actief." -ForegroundColor Green
}
else {
    Write-Host "[FOUT] Kon het plan niet dupliceren. Is powercfg wel beschikbaar?" -ForegroundColor Red
}


