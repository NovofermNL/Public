###################################################################
########## Novoferm Nederland – Remove-AppX.ps1 ###################
###################################################################

Write-Host "OOBE Phase – Appx-verwijdering gestart"

# Inlezen lijst vanuit JSON
$apps = Get-Content 'C:\Windows\Temp\RemoveAppx.json' | ConvertFrom-Json

foreach ($app in $apps) {
    Write-Host "Verwijder Appx (per gebruiker): $app"
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue

    Write-Host "Verwijder Appx (provisioned): $app"
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app | ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

Write-Host "OOBE Phase – Appx-verwijdering voltooid"

# OOBEDeploy uitvoeren voor eventuele extra setup
Start-OOBEDeploy -CustomProfile OSDDeploy
