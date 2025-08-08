foreach ($function in $functionList) {
    $url = "https://raw.githubusercontent.com/NovofermNL/Public/main/NovoTools/Functions/$function.ps1"

    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Method Head -ErrorAction Stop
        if ($response.StatusCode -ne 200) {
            Write-Warning "Functiebestand niet gevonden: $url"
            continue
        }
    }
    catch {
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
