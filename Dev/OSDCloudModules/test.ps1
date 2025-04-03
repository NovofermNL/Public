# TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Variabelen
$appx2remove = @(
    'OneNote','BingWeather','CommunicationsApps','OfficeHub','People','Skype','Solitaire','Xbox','ZuneMusic','ZuneVideo','FeedbackHub','TCUI'
)
#endregion

# Start OSDCloud
Start-OSDCloud -OSLanguage nl-nl -OSBuild 24H2 -OSEdition 'Pro' -OSLicense 'Volume' -SkipODT -OSVersion 'Windows 11' -ZTI -SkipAutopilot

# Verwijder APPX
Write-Host -ForegroundColor Gray "Even geduld, er wordt opgeruimd..."
Remove-AppxOnline -Name $appx2remove

Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloudRE installatie is voltooid"

Restart-Computer -Force
