<#
Scriptnaam: Remove-EntraDevicesComplete.ps1
Datum: 23-05-2025
Auteur: Novoferm Nederland BV

Beschrijving:
Verwijdert apparaten uit Microsoft Intune, Windows Autopilot en Entra ID (Azure AD) op basis van een lijst met serienummers.
De lijst wordt centraal ingeladen vanuit GitHub.

Gebruik:
1. Zet de lijst met serienummers in:
   https://github.com/NovofermNL/Public/blob/main/Prod/Entra/DeleteSerials.txt 
   (één serienummer per regel)

2. Pas zo nodig de opties bovenaan aan:
   - `$DryRun = $true` → Simulatie, geen verwijdering.
   - `$DryRun = $false` → Echte verwijdering.
   - `$EnableLogging = $true` → Logging activeren.
   - `$EnableLogging = $false` → Geen logbestand aanmaken.

3. Uitvoeren als administrator in **PowerShell 5.1**

Benodigdheden:
- Internettoegang
- Microsoft Graph API-machtigingen:
  • Device.ReadWrite.All  
  • DeviceManagementManagedDevices.ReadWrite.All  
  • Directory.ReadWrite.All  
  • DeviceManagementServiceConfig.ReadWrite.All
#>

# ======= Instellingen =======
$DryRun = $true
$EnableLogging = $true
$serialListUrl = "https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/Entra/DeleteSerials.txt"
$logPath = "C:\Windows\Temp\Remove-IntuneAutopilotDevices"
$logFile = Join-Path $logPath ("log-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".txt")

# ======= Logging functie =======
function Log {
    param ([string]$message)
    Write-Host $message
    if ($EnableLogging) {
        if (-not (Test-Path $logPath)) { New-Item -ItemType Directory -Path $logPath -Force | Out-Null }
        Add-Content -Path $logFile -Value ("[{0}] {1}" -f (Get-Date -Format "dd-MM-yyyy HH:mm:ss"), $message)
    }
}

# ======= Begin Script =======
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$modulesRequired = @(
    "Microsoft.Graph",
    "Microsoft.Graph.Intune",
    "Microsoft.Graph.DeviceManagement"
)

if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force
}
if ((Get-PSRepository -Name "PSGallery").InstallationPolicy -ne "Trusted") {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
}
foreach ($module in $modulesRequired) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Log "Module '$module' wordt geïnstalleerd..."
        Install-Module -Name $module -AllowClobber -Force
    }
}

Connect-MgGraph -Scopes "Device.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All", "Directory.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All"

# Serienummers ophalen
try {
    Log "Laad serienummers vanaf: $serialListUrl"
    $importedSerials = (Invoke-WebRequest -Uri $serialListUrl -UseBasicParsing).Content -split "`n"
} catch {
    Log "FOUT bij ophalen van serienummers vanaf GitHub: $($_)"
    exit 1
}

foreach ($serial in $importedSerials) {
    $serial = $serial.Trim()
    if (-not $serial) { continue }

    try {
        $device = Get-MgDeviceManagementManagedDevice -Filter "serialNumber eq '$serial'" 
        if ($device) {
            Log "Start met verwerking van apparaat: $($device.DeviceName) (Serial: ${serial})"

            try {
                if ($DryRun) {
                    Log "[DryRun] Intune-registratie zou worden verwijderd voor: ${serial}"
                } else {
                    Log "Verwijder Intune-registratie voor: ${serial}"
                    Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -Verbose -ErrorAction Stop
                    Start-Sleep -Seconds 10
                }
            } catch {
                Log "FOUT bij Intune-verwijdering voor ${serial}: $($_)"
            }

            try {
                $autopilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity | Where-Object { $_.SerialNumber -eq $serial }
                if ($autopilotDevice) {
                    if ($DryRun) {
                        Log "[DryRun] Autopilot-registratie zou worden verwijderd voor: ${serial}"
                    } else {
                        Log "Verwijder Autopilot-registratie voor: ${serial}"
                        Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $autopilotDevice.Id
                        Start-Sleep -Seconds 10
                    }
                }
            } catch {
                Log "FOUT bij Autopilot-verwijdering voor ${serial}: $($_)"
            }

            try {
                $entraIDValue = $device.AzureAdDeviceId
                $entraIDData = Get-MgDevice -Filter "DeviceId eq '$entraIDValue'"
                if ($DryRun) {
                    Log "[DryRun] Entra ID-registratie zou worden verwijderd voor: ${serial}"
                } else {
                    Log "Verwijder Entra ID-registratie voor: ${serial}"
                    Remove-MgDevice -DeviceId $entraIDData.Id
                    Start-Sleep -Seconds 10
                }
            } catch {
                Log "FOUT bij Entra ID-verwijdering voor ${serial}: $($_)"
            }

        } else {
            Log "GEEN apparaat gevonden voor serienummer: ${serial}"
        }
    } catch {
        Log "FOUT bij verwerking van ${serial}: $($_)"
    }
}

Log "Script voltooid."
