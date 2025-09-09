<#
Scriptnaam   : IntegreerUpdates.ps1
Datum        : 10-09-2025
Beschrijving : Integreert .msu-updates in een Windows-install.wim (eerst CUs, daarna .NET).
               Gebruikt ScratchDirectory, pauzeert Windows Search, voegt Defender-exclusie toe,
               en heeft robuuste dismount-retry met DISM-fallback en cleanup-mountpoints.
Organisatie  : Novoferm Nederland BV
#>

[CmdletBinding()]
param(
    [Parameter()] [string] $ImagePath    = "C:\Windows11\install.wim",
    [Parameter()] [string] $MountFolder  = "C:\Windows11\Mount",
    [Parameter()] [string] $UpdatesPath  = "C:\Updates",
    [Parameter()] [int]    $Index        = 5,
    [Parameter()] [switch] $SkipCleanup
)

# Vereisten/voorkeuren (Dominic)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

# Pad- en loginstellingen
$scriptName   = 'IntegreerUpdates'
$logRoot      = 'C:\Windows\Temp'
$logFolder    = Join-Path $logRoot $scriptName
$timestamp    = (Get-Date).ToString('dd-MM-yyyy_HH-mm-ss')
$logFile      = Join-Path $logFolder ("{0}_{1}.log" -f $scriptName, $timestamp)
$scratchDir   = "C:\Windows\Temp\DISM_Scratch"

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Ensure-Folder { param([string]$Path) if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null } }

# --- Start logging
Ensure-Folder -Path $logFolder
Ensure-Folder -Path $scratchDir
Start-Transcript -Path $logFile -Append | Out-Null

# --- Helpers voor locks / processen
function Wait-ServicingIdle {
    param([int]$TimeoutSec = 120)
    $stopAt = (Get-Date).AddSeconds($TimeoutSec)
    do {
        $p = Get-Process dism, dismhost, tiworker, trustedinstaller -ErrorAction SilentlyContinue
        if (-not $p) { return $true }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $stopAt)
    return $false
}

function Retry-Dismount {
    param([string]$MountDir, [int]$MaxTries = 3)

    # GC kan in .NET nog filehandles vasthouden (zeldzaam, maar goedkoop om te doen)
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()

    for ($i=1; $i -le $MaxTries; $i++) {
        try {
            Write-Host ("Poging {0}/{1}: Dismount-WindowsImage -Save..." -f $i,$MaxTries)
            Dismount-WindowsImage -Path $MountDir -Save -ErrorAction Stop
            return $true
        } catch {
            Write-Warning $_.Exception.Message
            # Fallback via dism.exe
            Write-Host "Fallback: dism.exe /Unmount-Image /MountDir:$MountDir /Commit"
            Start-Process -FilePath dism.exe -ArgumentList "/Unmount-Image","/MountDir:$MountDir","/Commit" -Wait -NoNewWindow
            Start-Sleep -Seconds (5 * $i)

            # Check status
            $stillMounted = $false
            try {
                $m = Get-WindowsImage -Mounted | Where-Object { $_.MountPath -ieq $MountDir -and $_.MountStatus -eq 'Mounted' }
                if ($m) { $stillMounted = $true }
            } catch { $stillMounted = Test-Path $MountDir } # ruwe check

            if (-not $stillMounted) { return $true }

            # Laatste poging? Doe cleanup-mountpoints en nog één discard
            if ($i -eq $MaxTries) {
                Write-Host "Forceer cleanup van mountpoints..."
                Start-Process -FilePath dism.exe -ArgumentList "/Cleanup-Mountpoints" -Wait -NoNewWindow
                try {
                    Dismount-WindowsImage -Path $MountDir -Discard -ErrorAction SilentlyContinue
                } catch {}
                return -not (Test-Path $MountDir)
            }
        }
    }
    return $false
}

# --- Hoofdlogica
$totaleStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Voorzorg: stop Windows Search, voeg Defender-exclusie toe
$wsearchWasRunning = $false
$defenderCmds = Get-Command Add-MpPreference -ErrorAction SilentlyContinue
$defenderExclAdded = $false

try {
    if (-not (Test-IsAdmin)) { throw "Dit script moet als Administrator worden uitgevoerd." }
    if (-not (Test-Path -LiteralPath $ImagePath)) { throw "Bestand niet gevonden: $ImagePath" }
    if (-not (Test-Path -LiteralPath $UpdatesPath)) { throw "Updates-pad niet gevonden: $UpdatesPath" }
    Ensure-Folder -Path $MountFolder

    # Windows Search pauzeren (indexer kan locks veroorzaken)
    try {
        $svc = Get-Service WSearch -ErrorAction Stop
        if ($svc.Status -eq 'Running') {
            $wsearchWasRunning = $true
            Write-Host "Windows Search (WSearch) stoppen..."
            Stop-Service WSearch -Force -ErrorAction Stop
        }
    } catch { Write-Host "Kon WSearch niet stoppen: $($_.Exception.Message)" }

    # Defender-exclusie voor mountfolder
    if ($defenderCmds) {
        try {
            Add-MpPreference -ExclusionPath $MountFolder -ErrorAction Stop
            $defenderExclAdded = $true
            Write-Host "Defender-exclusie toegevoegd: $MountFolder"
        } catch { Write-Host "Kon Defender-exclusie niet toevoegen: $($_.Exception.Message)" }
    }

    # Als mount al in gebruik is: discard voor schone start
    try {
        $mounted = Get-WindowsImage -Mounted | Where-Object { $_.MountPath -ieq $MountFolder -and $_.MountStatus -eq 'Mounted' }
        if ($mounted) {
            Write-Host "Mount-pad in gebruik. Dismount (discard) voor schone start."
            Dismount-WindowsImage -Path $MountFolder -Discard -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    } catch { }

    Write-Host "Mounten van image..."
    Mount-WindowsImage -Path $MountFolder -ImagePath $ImagePath -Index $Index -CheckIntegrity -ScratchDirectory $scratchDir

    # Updates verzamelen en sorteren
    $allMsuFiles = Get-ChildItem -Path $UpdatesPath -Filter *.msu -File
    $cuUpdates   = @($allMsuFiles | Where-Object { $_.Name -notlike "*ndp*" } | Sort-Object Name)
    $ndpUpdates  = @($allMsuFiles | Where-Object { $_.Name -like "*ndp*" }   | Sort-Object Name)
    $updatesInVolgorde = @($cuUpdates + $ndpUpdates)

    if ($updatesInVolgorde.Count -eq 0) {
        Write-Warning "Geen .msu-bestanden gevonden in $UpdatesPath. Er wordt niets geïntegreerd."
    } else {
        Write-Host ("Totaal {0} updates (CUs: {1}, .NET: {2})." -f $updatesInVolgorde.Count, $cuUpdates.Count, $ndpUpdates.Count)
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
                Add-WindowsPackage -PackagePath $msu.FullName -Path $MountFolder -LogLevel 3 -ScratchDirectory $scratchDir -ErrorAction Stop
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
            Start-Process -FilePath "dism.exe" -ArgumentList "/Image:$MountFolder","/Cleanup-Image","/StartComponentCleanup","/ScratchDir:$scratchDir" -Wait -NoNewWindow
        } catch {
            Write-Warning ("Cleanup mislukt: {0}" -f $_.Exception.Message)
        }
    } else {
        Write-Host "Component cleanup overgeslagen op verzoek."
    }

    # Wacht tot alle servicing-processen klaar zijn
    if (-not (Wait-ServicingIdle -TimeoutSec 180)) {
        Write-Warning "Servicing processen leken lang actief te blijven (dism/dismhost/tiworker/trustedinstaller)."
    }

    Write-Host ""
    Write-Host "Committen en dismounten..."
    $ok = Retry-Dismount -MountDir $MountFolder -MaxTries 3
    if (-not $ok) { throw "De map kan niet volledig worden ontkoppeld. Er lijken nog handles actief op $MountFolder." }

    Write-Host "Gereed."
}
catch {
    Write-Error $_.Exception.Message
    Write-Host "Incident-handling: forceer cleanup-mountpoints en discard als dat nodig is."
    try {
        Start-Process -FilePath dism.exe -ArgumentList "/Cleanup-Mountpoints" -Wait -NoNewWindow
        Dismount-WindowsImage -Path $MountFolder -Discard -ErrorAction SilentlyContinue
    } catch { }
    throw
}
finally {
    # Herstel Windows Search
    if ($wsearchWasRunning) {
        try { Start-Service WSearch -ErrorAction Stop } catch { Write-Host "Kon WSearch niet starten: $($_.Exception.Message)" }
    }
    # Defender-exclusie terugdraaien
    if ($defenderExclAdded -and (Get-Command Remove-MpPreference -ErrorAction SilentlyContinue)) {
        try { Remove-MpPreference -ExclusionPath $MountFolder -ErrorAction Stop } catch { }
    }

    $totaleStopwatch.Stop()
    Write-Host ("Totale duur: {0}" -f $totaleStopwatch.Elapsed.ToString())
    try { Stop-Transcript | Out-Null } catch { }
    Write-Host ("Logbestand: {0}" -f $logFile)
}
