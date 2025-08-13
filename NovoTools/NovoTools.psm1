<# Module: NovoTools.psm1
 Beschrijving: Laadt alleen functiedefinities uit de Functions-map in de GitHub-repo
 Auteur: Novoferm Nederland BV  Datum: 13-08-2025 #>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Headers = @{
  'User-Agent'      = 'NovoTools-Loader'
  'Accept'          = 'application/vnd.github.v3+json'
}

$functionsApiUrl = 'https://api.github.com/repos/NovofermNL/Public/contents/NovoTools/Functions'

try {
    $files = Invoke-RestMethod -Uri $functionsApiUrl -Headers $Headers -UseBasicParsing
} catch {
    Write-Warning "Kan de lijst met functies niet ophalen: $($_.Exception.Message)"
    return
}

foreach ($file in $files) {
    if ($file.name -like '*.ps1') {
        try {
            $code = Invoke-RestMethod -Uri $file.download_url -Headers $Headers -UseBasicParsing
            if ([string]::IsNullOrWhiteSpace($code)) {
                Write-Warning "Leeg bestand: $($file.name) ($($file.download_url))"
                continue
            }

            $null = $tokens = $errors = $null
            $ast  = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Warning "Syntaxfout in $($file.name): $($errors[0].Message)"
                continue
            }

            $funcAsts = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            if ($funcAsts.Count -eq 0) {
                Write-Warning "Geen functies gevonden in $($file.name); sla over (mogelijk top-level code)."
                continue
            }

            foreach ($func in $funcAsts) {
                Invoke-Expression $func.Extent.Text
            }
        } catch {
            Write-Warning "Kon functie niet laden: $($file.name) - $($_.Exception.Message)"
        }
    }
}

# (Optioneel) specifieker exporteren:
# Export-ModuleMember -Function Install-NFWindowsUpdates, Invoke-NFOobeUpdateWindows, Remove-AppxOnline, Remove-FeedbackHub, Remove-NFAppxBloatware
