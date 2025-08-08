foreach ($function in $functionList) {
    $url = "https://raw.githubusercontent.com/NovofermNL/Public/main/NovoTools/Functions/$function.ps1"

    if (-not (Invoke-WebRequest -Uri $url -UseBasicParsing -Method Head -ErrorAction SilentlyContinue)) {
        Write-Warning "Functiebestand niet gevonden: $url"
        continue
    }

    try {
        Invoke-Expression (Invoke-RestMethod -Uri $url -UseBasicParsing)
    }
    catch {
        Write-Warning "Kon functie niet laden: $function - $_"
    }
}
