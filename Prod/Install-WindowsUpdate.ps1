
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-Transcript -Path "C:\Windows\Temp\-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" -Force

# Zorg dat tijdelijke execution policy niet in de weg zit
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

# Controleer of NuGet beschikbaar is
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Cyan "NuGet-provider niet gevonden, installeren wordt gestart..."
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers -ErrorAction Stop
} else {
    Write-Host -ForegroundColor Green "NuGet-provider is al geïnstalleerd"
}

# Zorg dat PSGallery vertrouwd is
$psGallery = Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue
if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
}

# Functie om PSWindowsUpdate te installeren of bij te werken
function Ensure-PSWindowsUpdate {
    $ModuleName = "PSWindowsUpdate"
    $RequiredVersion = [version]'2.2.0.3'

    $installedModule = Get-Module -Name $ModuleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

    if ($installedModule) {
        if ($installedModule.Version -lt $RequiredVersion) {
            Write-Host -ForegroundColor Cyan "$ModuleName versie $($installedModule.Version) is oud, update wordt uitgevoerd..."
            Update-Module -Name $ModuleName -Force -Scope AllUsers -ErrorAction SilentlyContinue
        } else {
            Write-Host -ForegroundColor Cyan "$ModuleName versie $($installedModule.Version) is up-to-date"
        }
    } else {
        Write-Host -ForegroundColor Cyan "$ModuleName is niet geïnstalleerd, installatie wordt gestart..."
        Install-Module -Name $ModuleName -Force -Scope AllUsers -ErrorAction SilentlyContinue
    }

    Import-Module $ModuleName -Force -ErrorAction SilentlyContinue
}

# Voer Windows updates uit (zonder reboot)
Write-Host -ForegroundColor Cyan 'Windows updates worden geïnstalleerd...'
Ensure-PSWindowsUpdate

if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
    Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
    Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Preview' -NotKBArticleID 'KB890830','KB5005463','KB4481252'" -Wait
}

# Voer driver updates uit (niet voor HP)
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
if ($Manufacturer -notmatch "HP") {
    Write-Host -ForegroundColor Cyan 'Driver updates worden uitgevoerd via PSWindowsUpdate'
    Ensure-PSWindowsUpdate

    if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
        Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -UpdateType Driver -AcceptAll -IgnoreReboot" -Wait
    }
} else {
    Write-Host -ForegroundColor Yellow "HP-systeem gedetecteerd – driver updates worden overgeslagen"
}

Stop-Transcript
