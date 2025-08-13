function Install-NFWindowsUpdates {
    [CmdletBinding()]
    param(
        [string]$BasePath = "\\Novoferm.info\dfs\Repository\OS\CU",
        [string]$UpdatePath,
        [ValidateSet('Auto','x64','arm64')]
        [string]$Architecture = 'Auto'
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $LogPath = "C:\Windows\Temp\CU-Installatie.log"

    function Get-TS { (Get-Date).ToString('dd-MM-yyyy HH:mm:ss') }

    if (-not $UpdatePath) {
        $archDetected = $null
        if ($Architecture -eq 'Auto') {
            $rawArch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
            switch -Regex ($rawArch) {
                'ARM64' { $archDetected = 'arm64'; break }
                'AMD64|X64' { $archDetected = 'x64'; break }
                default { $archDetected = 'x64' }
            }
        } else {
            $archDetected = $Architecture
        }

        $UpdatePath = Join-Path -Path $BasePath -ChildPath $archDetected

        $srcVar = if ($env:PROCESSOR_ARCHITEW6432) { 'PROCESSOR_ARCHITEW6432' } else { 'PROCESSOR_ARCHITECTURE' }
        Add-Content $LogPath ("[{0}] Architectuur: {1} (bron: {2})" -f (Get-TS), $archDetected, $srcVar)
        Add-Content $LogPath ("[{0}] Gekozen UpdatePath: {1}" -f (Get-TS), $UpdatePath)
    }
    else {
        Add-Content $LogPath ("[{0}] UpdatePath geforceerd: {1}" -f (Get-TS), $UpdatePath)
    }

    if (-not (Test-Path -Path $UpdatePath)) {
        Write-Warning "Updatepad bestaat niet: $UpdatePath"
        Add-Content $LogPath ("[{0}] FOUT: Updatepad bestaat niet: {1}" -f (Get-TS), $UpdatePath)
        return
    }

    $Updates = Get-ChildItem -Path $UpdatePath -Filter *.msu -ErrorAction SilentlyContinue | Sort-Object Name
    if (-not $Updates) {
        Write-Warning "Geen .msu-bestanden gevonden in $UpdatePath"
        Add-Content $LogPath ("[{0}] Geen .msu-bestanden gevonden in {1}" -f (Get-TS), $UpdatePath)
        return
    }

    $Total   = $Updates.Count
    $Counter = 0
    Add-Content $LogPath ("[{0}] Start installatie van {1} update(s) uit {2}" -f (Get-TS), $Total, $UpdatePath)

    foreach ($Update in $Updates) {
        $Counter++
        $progressMsg = "Bezig met update $Counter van $Total: $($Update.Name)"
        Write-Progress -Activity "Updates installeren" -Status $progressMsg -PercentComplete (($Counter / $Total) * 100)

        Add-Content $LogPath ("[{0}] Start: {1}" -f (Get-TS), $Update.Name)

        $proc = Start-Process -FilePath "wusa.exe" -ArgumentList "`"$($Update.FullName)`" /quiet /norestart" -PassThru -Wait
        $code = $null
        try { $code = $proc.ExitCode } catch { }

        Add-Content $LogPath ("[{0}] Klaar: {1} (ExitCode: {2})" -f (Get-TS), $Update.Name, ($code -as [string]))
    }

    Write-Progress -Activity "Updates installeren" -Completed
    Write-Output "Alle updates zijn verwerkt. Raadpleeg het logbestand: $LogPath"
}
