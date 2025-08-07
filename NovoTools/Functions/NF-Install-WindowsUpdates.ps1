function NF-Install-WindowsUpdates {

    param (
        [string]$UpdatePath = "\\Novoferm.info\dfs\Repository\OS\CU"
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $LogPath = "C:\Windows\Temp\CU-Installatie.log"
    $Updates = Get-ChildItem -Path $UpdatePath -Filter *.msu

    if (-not $Updates) {
        Write-Warning "Geen .msu bestanden gevonden in $UpdatePath"
        return
    }

    $Total = $Updates.Count
    $Counter = 0

    foreach ($Update in $Updates) {
        $Counter++
        $ProgressMessage = "Bezig met update $Counter van $Total $($Update.Name)"

        Write-Progress -Activity "Updates installeren" `
            -Status $ProgressMessage `
            -PercentComplete (($Counter / $Total) * 100)

        $timestamp = (Get-Date).ToString('dd-MM-yyyy HH:mm:ss')
        Add-Content $LogPath "[$timestamp] Start: $($Update.Name)"

        Start-Process -FilePath "wusa.exe" `
            -ArgumentList "`"$($Update.FullName)`" /quiet /norestart" `
            -Wait

        $timestamp = (Get-Date).ToString('dd-MM-yyyy HH:mm:ss')
        Add-Content $LogPath "[$timestamp] Klaar: $($Update.Name)"
    }

    Write-Progress -Activity "Updates installeren" -Completed
    Write-Output "Alle updates zijn geïnstalleerd. Logbestand: $LogPath"
}
