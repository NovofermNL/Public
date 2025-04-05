  $RemoveAppx     = @(
        'Microsoft.549981C3F5F10',
        'Microsoft.BingWeather',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MixedReality.Portal',
        'Microsoft.Office.OneNote',
        'Microsoft.People',
        'Microsoft.SkypeApp',
        'Microsoft.Wallet',
        'Microsoft.WindowsCamera',
        'microsoft.windowscommunicationsapps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo'
    )

    # Schrijf lijst naar JSON-bestand dat later gebruikt wordt door OOBE.cmd
    $RemoveAppx | ConvertTo-Json | Out-File -FilePath "C:\Windows\Temp\RemoveAppx.json" -Encoding ascii -Force

Start-Process powershell -ArgumentList "-NoLogo -Command Set-ExecutionPolicy Bypass -Force" -Wait


$RemoveAppx = Get-Content -Path 'C:\Windows\Temp\RemoveAppx.json' | ConvertFrom-Json

foreach ($App in $RemoveAppx) {
    Write-Host "Verwijder Appx voor alle gebruikers: $App"
    Get-AppxPackage -AllUsers -Name $App | Remove-AppxPackage -ErrorAction SilentlyContinue

    Write-Host "Verwijder Appx Provisioned Package: $App"
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $App | ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}


