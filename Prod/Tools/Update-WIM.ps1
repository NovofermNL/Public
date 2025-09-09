<# 
Scriptnaam   : IntegreerUpdates.ps1
Datum        : 10-09-2025
Beschrijving : Integreert alle .msu-updates in een Windows-install.wim image (eerst CUs, daarna .NET).
Dominic Bruins

Logging in C:\Windows\Temp\
#>

[CmdletBinding()]
param(
    [Parameter()] [string] $ImagePath   = "C:\Windows11\install.wim",
    [Parameter()] [string] $MountFolder = "C:\Windows11\Mount",
    [Parameter()] [string] $UpdatesPath = "C:\Updates",
    [Parameter()] [int]    $Index       = 5,
    [Parameter()] [switch] $SkipCleanup
)

# Forceren van TLS 1.2 voor eventuele toekomstige web-calls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Algemene instellingen
$ErrorActionPreference = 'Stop'
$scriptName   = 'IntegreerUpdates'
$logRoot      = 'C:\Windows\Temp'
$logFolder    = Join-Path $logRoot $scriptName
$timestamp    = (Get-Date).ToString('dd-MM-yyyy_HH-mm-ss')
$logFile      = Join-Path $logFolder ("{0}_{1}.log" -f $scriptName, $timestamp)

# Helpers
function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Folder {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Start logging
Ensure-Folder -Path $logFolder
Start-Transcript -Path $logFile -Append | Out-Null

# Stopwatch total
$totaleStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    if (-not (Test-IsAdmin)) { throw "Dit script moet als Administrator worden uitgevoerd." }

    if (-not (Test-Path -LiteralPath $ImagePath)) { throw "Bestand niet gevonden: $ImagePath" }
    if (-not (Test-Path -LiteralPath $UpdatesPath)) { throw "Updates-pad niet gevonden: $UpdatesPath" }

    Ensure-Folder -Path $MountFolder

    Write-Host "Mounten van image..."
    # Als al gemount is, eerst dismounten zonder save (veiligheidsnet)
    try {
        $mounted = Get-WindowsImage -Mounted | Where-Object { $_.MountPath -ieq $MountFolder -and $_.MountStatus -eq 'Mounted' }
        if ($mounted) {
            Write-Host "Mount-pad is al in gebruik. Dismount zonder opslaan voor schone start."
            Dismount-WindowsImage -Path $MountFolder -Discard -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    } catch { }

    Mount-WindowsImage -Path $MountFolder -ImagePath $ImagePath -Index $Index -CheckIntegrity

    # Updates verzamelen en sorteren
    $allMsuFiles = Get-ChildItem -Path $UpdatesPath -Filter *.msu -File -ErrorAction Stop

    # Eerst cumulatieve updates (geen ndp), alfabetisch; daarna ndp (alfabetisch)
    $cuUpdates  = @($allMsuFiles | Where-Object { $_.Name -notlike "*ndp*" } | Sort-Object Name)
    $ndpUpdates = @($allMsuFiles | Where-Object { $_.Name -like "*ndp*" }   | Sort-Object Name)

    $updatesInVolgorde = @($cuUpdates + $ndpUpdates)

    if ($updatesInVolgorde.Count -eq 0) {
        Write-Warning "Geen .msu-bestanden gevonden in $UpdatesPath. Er wordt niets geïntegreerd."
    } else {
        Write-Host ("Totaal {0} updates gevonden (CUs: {1}, .NET: {2})." -f $updatesInVolgorde.Count, $cuUpdates.Count, $ndpUpdates.Count)

        $total = $updatesInVolgorde.Count
        $count = 0

        foreach ($msu in $updatesInVolgorde) {
            $count++
            $updateTimer = [System.Diagnostics.Stopwatch]::StartNew()
            $percent = [math]::Round(($count / $total) * 100, 2)

            Write-Progress -Activity "Integratie van updates" -Status "Bezig met $($msu.Name) ($count van $total)" -PercentComplete $percent
            Write-Host ""
            Write-Host ("[{0}/{1}] Toevoegen van {2}..." -f $count, $total, $msu.Name)

            try {
                # Add-WindowsPackage logt standaard naar DISM logs; LogLevel 3 = Verbose
                Add-WindowsPackage -PackagePath $msu.FullName -Path $MountFolder -LogLevel 3 -ErrorAction Stop
            } catch {
                Write-Warning ("Fout bij toevoegen van {0}: {1}" -f $msu.Name, $_.Exception.Message)
                continue
            } finally {
                $updateTimer.Stop()
                Write-Host ("Duur voor {0}: {1}" -f $msu.Name, $updateTimer.Elapsed.ToString())
            }
        }
    }

    if (-not $SkipCleanup.IsPresent) {
        Write-Host ""
        Write-Host "Component cleanup uitvoeren (DISM) ..."
        try {
            # DISM cleanup kan fouten geven als er niets op te schonen valt; dat is niet kritisch
            Start-Process -FilePath "dism.exe" -ArgumentList "/Image:$MountFolder","/Cleanup-Image","/StartComponentCleanup" -Wait -NoNewWindow
        } catch {
            Write-Warning ("Cleanup mislukt: {0}" -f $_.Exception.Message)
        }
    } else {
        Write-Host "Component cleanup overgeslagen op verzoek."
    }

    Write-Host ""
    Write-Host "Committen en dismounten..."
    Dismount-WindowsImage -Path $MountFolder -Save -ErrorAction Stop
    Write-Host "Gereed."
}
catch {
    Write-Error $_.Exception.Message
    Write-Host "Incident-handling: probeer dismount zonder opslaan om mount lock te voorkomen."
    try {
        Dismount-WindowsImage -Path $MountFolder -Discard -ErrorAction SilentlyContinue
    } catch { }
    throw
}
finally {
    $totaleStopwatch.Stop()
    Write-Host ("Totale duur: {0}" -f $totaleStopwatch.Elapsed.ToString())
    try { Stop-Transcript | Out-Null } catch { }
    Write-Host ("Logbestand: {0}" -f $logFile)
}
