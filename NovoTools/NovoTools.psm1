# Lijst van functies (zonder .ps1 extensie!)
$functionList = @(
    "Install-WindowsUpdates"
    "Update-HPDrivers"
)

foreach ($function in $functionList) {
    $url = "https://raw.githubusercontent.com/NovofermNL/Public/main/NovoTools/Functions/$function.ps1"
    try {
        Invoke-Expression (Invoke-RestMethod -Uri $url -UseBasicParsing)
    }
    catch {
        Write-Warning "Kon functie niet laden: $function - $_"
    }
}
