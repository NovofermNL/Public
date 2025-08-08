# Automatisch alle functies ophalen uit de Functions-map in je repo
$functionsApiUrl = "https://api.github.com/repos/NovofermNL/Public/contents/NovoTools/Functions"

try {
    $files = Invoke-RestMethod -Uri $functionsApiUrl -UseBasicParsing
} catch {
    Write-Warning "Kan de lijst met functies niet ophalen: $_"
    return
}

foreach ($file in $files) {
    if ($file.name -like '*.ps1') {
        $functionName = [System.IO.Path]::GetFileNameWithoutExtension($file.name)
        $url = $file.download_url

        try {
            $code = Invoke-RestMethod -Uri $url -UseBasicParsing
            if (-not [string]::IsNullOrWhiteSpace($code)) {
                Invoke-Expression $code
            } else {
                Write-Warning "Leeg bestand: $functionName ($url)"
            }
        } catch {
            Write-Warning "Kon functie niet laden: $functionName - $_"
        }
    }
}
