###################################################################
########## Novoferm Nederland W11-24H2 PostInstall.ps1 ############
###################################################################

# Inlezen Appx-lijst uit JSON-bestand
$RemoveAppx = Get-Content -Path 'C:\Windows\Temp\RemoveAppx.json' | ConvertFrom-Json

foreach ($App in $RemoveAppx) {
    Write-Host "Verwijder Appx voor alle gebruikers: $App"
    Get-AppxPackage -AllUsers -Name $App | Remove-AppxPackage -ErrorAction SilentlyContinue

    Write-Host "Verwijder Appx provisioned package: $App"
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $App | ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

# Uitvoeren van aanvullende OSDDeploy-taken
Start-OOBEDeploy -CustomProfile OSDDeploy
