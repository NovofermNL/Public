function NF-Update-HPDrivers {
    <#
    .SYNOPSIS
        Update HP drivers op basis van het OSDCloudTS script van OSDeploy.
    .DESCRIPTION
        Voert automatisch de HP driver update uit als het systeem een HP is.
        Gebruikt de publieke OSDCloudTS functie van OSDeploy GitHub.
    .NOTES
        Gebaseerd op: https://github.com/OSDeploy/OSD/blob/master/Public/OSDCloudTS/Invoke-HPDriverUpdate.ps1
    .LINK
        https://github.com/OSDeploy/OSD
    #>

    if ((Get-CimInstance -Class Win32_ComputerSystem).Manufacturer -like "*HP*") {
        Write-Host "HP-systeem gedetecteerd, starten met driver update..."
        Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/OSDeploy/OSD/master/Public/OSDCloudTS/Invoke-HPDriverUpdate.ps1')
    }
    else {
        Write-Host "Geen HP-systeem, driver update wordt overgeslagen."
    }
}
