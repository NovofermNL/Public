<# 
Scriptnaam: Configure-OutlookAutodiscover-OnPrem.ps1
Beschrijving: Configureert Outlook om alléén on-prem Exchange te gebruiken voor autodiscover.
#>

$regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\AutoDiscover"

# Zorg dat de registry key bestaat
If (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Stel de juiste autodiscover voorkeuren in
Set-ItemProperty -Path $regPath -Name "ExcludeExplicitO365Endpoint" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath -Name "ExcludeHttpsRootDomain" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath -Name "ExcludeHttpsAutoDiscoverDomain" -Value 0 -Type DWord
Set-ItemProperty -Path $regPath -Name "ExcludeScpLookup" -Value 0 -Type DWord
Set-ItemProperty -Path $regPath -Name "ExcludeSrvRecord" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath -Name "ExcludeLastKnownGoodUrl" -Value 1 -Type DWord
Set-ItemProperty -Path $regPath -Name "ZeroConfigExchange" -Value 1 -Type DWord

Write-Output "Outlook Autodiscover is ingesteld voor on-prem Exchange."
