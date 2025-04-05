$RemoveAppx = @(
    "Clipchamp.Clipchamp_3.0.10220.0_neutral_~_yxz26nhyzhsrt",
    "Microsoft.BingNews_4.1.24002.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.BingSearch_2022.0.79.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.BingWeather_4.53.52892.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.GamingApp_2024.311.2341.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.GetHelp_10.2302.10601.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.MicrosoftOfficeHub_18.2308.1034.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.MicrosoftSolitaireCollection_4.19.3190.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.MicrosoftStickyNotes_4.6.2.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.OutlookForWindows_1.0.0.0_neutral__8wekyb3d8bbwe",
    "Microsoft.PowerAutomateDesktop_11.2401.28.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.Todos_2.104.62421.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.Windows.DevHome_0.100.128.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.WindowsAlarms_2022.2312.2.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_2024.125.1522.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.WindowsSoundRecorder_2021.2312.5.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.WindowsTerminal_3001.18.10301.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.Xbox.TCUI_1.23.28005.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.XboxGamingOverlay_2.624.1111.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.XboxIdentityProvider_12.110.15002.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.XboxSpeechToTextOverlay_1.97.17002.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.YourPhone_1.24012.105.0_neutral_~_8wekyb3d8bbwe",
    "Microsoft.ZuneMusic_11.2312.8.0_neutral_~_8wekyb3d8bbwe",
    "MicrosoftWindows.Client.WebExperience_424.1301.270.9_neutral_~_cw5n1h2txyewy",
    "MSTeams_1.0.0.0_x64__8wekyb3d8bbwe"
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


