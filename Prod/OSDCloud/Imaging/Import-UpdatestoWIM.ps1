<#
Scriptnaam: Import-UpdatestoWIM.ps1
Datum: 05-08-2025
Beschrijving: Integreert alle .msu-updates in een Windows-install.wim image
#>

$ImagePath    = "C:\Windows11\Win11_24H2_Dutch_x64\sources\install.wim"
$MountFolder  = "C:\Windows11\Mount"
$UpdatesPath  = "\\Novoferm.info\dfs\Repository\OS\CU"
$BackupPath   = $ImagePath -replace "\.wim$", "-backup.wim"

# Maak een backup
Copy-Item $ImagePath $BackupPath -Force
Write-Host "Backup gemaakt: $BackupPath" -ForegroundColor DarkYellow

# Start totaaltimer
$totaleStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Mount image
Write-Host "Mounten van image..." -ForegroundColor Cyan
Mount-WindowsImage -Path $MountFolder -ImagePath $ImagePath -Index 5 -CheckIntegrity

# Verzamel .msu-bestanden, zonder SSU's
$allMsuFiles = Get-ChildItem -Path $UpdatesPath -Filter *.msu
$updates = $allMsuFiles | Where-Object { $_.Name -notmatch "servicingstack|SSU" } | Sort-Object Name

$total = $updates.Count
$count = 0

foreach ($msu in $updates) {
    $count++
    $updateTimer = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Progress -Activity "Integratie van updates" -Status "Bezig met $($msu.Name) ($count van $total)" -PercentComplete (($count / $total) * 100)

    Write-Host "`n[$count/$total] Toevoegen van $($msu.Name)..." -ForegroundColor Green

    try {
        Add-WindowsPackage -PackagePath $msu.FullName -Path $MountFolder -LogLevel 3 -ErrorAction Stop
    } catch {
        Write-Host "Fout bij toevoegen van $($msu.Name): $_" -ForegroundColor Red
        continue
    }

    $updateTimer.Stop()
    Write-Host "Duur voor $($msu.Name): $($updateTimer.Elapsed.ToString())" -ForegroundColor DarkGray
}

# Cleanup
Write-Host "`nVoer component cleanup uit..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "dism.exe" -ArgumentList "/Image:$MountFolder", "/Cleanup-Image", "/StartComponentCleanup" -Wait -NoNewWindow
} catch {
    Write-Host "Cleanup mislukt: $_" -ForegroundColor Red
}

# Dismount & commit
Write-Host "`nCommitten en dismounten..." -ForegroundColor Yellow
try {
    Dismount-WindowsImage -Path $MountFolder -Save -ErrorAction Stop
} catch {
    Write-Host "Fout bij dismount: $_" -ForegroundColor Red
}

# Totale tijd
$totaleStopwatch.Stop()
Write-Host "`nTotale duur: $($totaleStopwatch.Elapsed.ToString())" -ForegroundColor Magenta
