<#
    Scriptnaam : Install-NFWindowsUpdates.ps1
    Datum      : 13-08-2025
    Beschrijving:
      Installeert .msu-updates. Bepaalt automatisch of het systeem ARM64 of x64 is
      en kiest op basis daarvan de juiste update-map (submap 'arm64' of 'x64').
      Optioneel kun je een UpdatePath forceren.
    Organisatie: Novoferm Nederland BV
#>

function Install-NFWindowsUpdates {
    [CmdletBinding()]
    param(
        # Gebruik óf BasePath (met automatische submap-selectie) óf forceer een volledige updatepad met UpdatePath
        [string]$BasePath = "\\Novoferm.info\dfs\Repository\OS\CU",
        [string]$UpdatePath,
        [ValidateSet('Auto','x64','arm64')]
        [string]$Architecture = 'Auto'
    )

    # TLS12 conform jouw standaard
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Logging conform jouw voorkeur
    $LogPath = "C:\Windows\Temp\CU-Installatie.log"

    # --- Helper: timestamp (DD-MM-YYYY HH:mm:ss) ---
    function Get-TS { (Get-Date).ToString('dd-MM-yyyy HH:mm:ss') }

    # --- Bepaal architectuur indien nodig ---
    if (-not $UpdatePath) {
        $archDetected = $null

        if ($Architecture -eq 'Auto') {
            # Robuuste detectie (voorkomt WOW64-verwarring)
            $rawArch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
            switch -Regex ($rawArch) {
                'ARM64' { $archDetected = 'arm64'; break }
                'AMD64|X64' { $archDetected = 'x64'; break }
                default { $archDetected = 'x64' } # veilige default
            }
        } else {
            $archDetected = $Architecture
        }

        $UpdatePath = Join-Path -Path $BasePath -ChildPath $archDetected
        Add-Content $LogPath "[{0}] Architectuur: {1} (bron: {2})" -f (Get-TS), $archDetected, ($env:PROCESSOR_ARCHITEW6432 ? 'PROCESSOR_ARCHITEW6432' : 'PROCESSOR_ARCHITECTURE')
        Add-Content $LogPath "[{0}] Gekozen UpdatePath: {1}" -f (Get-TS), $UpdatePath
    }
    else {
        Add-Content $LogPath "[{0}] UpdatePath geforceerd: {1}" -f (Get-TS), $UpdatePath
    }

    if (-not (Test-Path -Path $UpdatePath)) {
        Write-Warning "Updatepad bestaat niet: $UpdatePath"
        Add-Content $LogPath "[{0}] FOUT: Updatepad bestaat niet: {1}" -f (Get-TS), $UpdatePath
        return
    }

    $Updates = Get-ChildItem -Path $UpdatePath -Filter *.msu -ErrorAction SilentlyContinue | Sort-Object Name
    if (-not $Updates) {
        Write-Warning "Geen .msu-bestanden gevonden in $UpdatePath"
        Add-Content $LogPath "[{0}] Geen .msu-bestanden gevonden in {1}" -f (Get-TS), $UpdatePath
        return
    }

    $Total   = $Updates.Count
    $Counter = 0

    Add-Content $LogPath "[{0}] Start installatie van {1} update(s) uit {2}" -f (Get-TS), $Total, $UpdatePath

    foreach ($Update in $Updates) {
        $Counter++
        $progressMsg = "Bezig met update $Counter van $Total: $($Update.Name)"

        Write-Progress -Activity "Updates installeren" -Status $progressMsg -PercentComplete (($Counter / $Total) * 100)

        Add-Content $LogPath "[{0}] Start: {1}" -f (Get-TS), $Update.Name

        # Start WUSA
        $proc = Start-Process -FilePath "wusa.exe" `
                              -ArgumentList "`"$($Update.FullName)`" /quiet /norestart" `
                              -PassThru -Wait

        # (Optioneel) Exitcode loggen; WUSA geeft vaak 0 of 3010 (reboot required)
        $code = try { $proc.ExitCode } catch { $null }
        Add-Content $LogPath "[{0}] Klaar: {1} (ExitCode: {2})" -f (Get-TS), $Update.Name, ($code -as [string])
    }

    Write-Progress -Activity "Updates installeren" -Completed
    Write-Output "Alle updates zijn verwerkt. Raadpleeg het logbestand: $LogPath"
}
