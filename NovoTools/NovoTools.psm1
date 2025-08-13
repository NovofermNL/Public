<# 
    Module: NovoTools.psm1
    Beschrijving: Laadt alle functies uit de Functions-map in de GitHub-repo, 
    waarbij alleen functiedefinities worden ingeladen en geen top-level code wordt uitgevoerd.
    Auteur: Novoferm Nederland BV
    Datum: 13-08-2025
#>

# GitHub API URL naar de Functions-map
$functionsApiUrl = "https://api.github.com/repos/NovofermNL/Public/contents/NovoTools/Functions"

try {
    $files = Invoke-RestMethod -Uri $functionsApiUrl -UseBasicParsing
} catch {
    Write-Warning "Kan de lijst met functies niet ophalen: $_"
    return
}

foreach ($file in $files) {
    if ($file.name -like '*.ps1') {
        try {
            $code = Invoke-RestMethod -Uri $file.download_url -UseBasicParsing

            if ([string]::IsNullOrWhiteSpace($code)) {
                Write-Warning "Leeg bestand: $($file.name) ($($file.download_url))"
                continue
            }

            # Parse de inhoud naar AST (Abstract Syntax Tree)
            $null = $tokens = $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

            if ($errors.Count -gt 0) {
                Write-Warning "Syntaxfout in $($file.name): $($errors[0].Message)"
                continue
            }

            # Zoek alleen naar functiedefinities
            $funcAsts = $ast.FindAll(
                { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
                $true
            )

            if ($funcAsts.Count -eq 0) {
                Write-Warning "Geen functies gevonden in $($file.name); mogelijk top-level code. Sla over."
                continue
            }

            # Laad elke functie in de huidige sessie
            foreach ($func in $funcAsts) {
                Invoke-Expression $func.Extent.Text
            }

        } catch {
            Write-Warning "Kon functie niet laden: $($file.name) - $_"
        }
    }
}
