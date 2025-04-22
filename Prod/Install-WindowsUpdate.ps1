<# 
Naam: Install-WindowsUpdate.ps1
Beschrijving: Installeert Windows Updates via PSWindowsUpdate, optioneel uit te schakelen via variabele ($updateWindows = $False)
Organisatie: Novoferm Nederland BV
#>

# Toggle voor updates
$EnableWindowsUpdate = $true

if (-not $EnableWindowsUpdate) {
    Write-Host "Windows Update is uitgeschakeld via scriptinstelling." -ForegroundColor Yellow
    return
}

# PSWindowsUpdate installeren indien nodig
try {
    if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
    }
    Import-Module PSWindowsUpdate -Force
}
catch {
    Write-Warning 'PSWindowsUpdate module niet beschikbaar of installatiefout.'
    return
}

# Start updates
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Malicious','Preview'
