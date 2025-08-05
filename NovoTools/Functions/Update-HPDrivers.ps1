if ((Get-CimInstance -Class Win32_ComputerSystem).Manufacturer -like "*HP*") {
    Write-Host "HP-systeem gedetecteerd, starten met driver update..."
    Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/OSDeploy/OSD/master/Public/OSDCloudTS/Invoke-HPDriverUpdate.ps1')
}
else {
    Write-Host "Geen HP-systeem, driver update wordt overgeslagen."
}
