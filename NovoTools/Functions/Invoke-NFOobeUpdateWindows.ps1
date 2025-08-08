function Invoke-NFOobeUpdateWindows {
    <#
    .SYNOPSIS
        Voert Windows Updates uit tijdens of na OOBE.
    .DESCRIPTION
        Controleert of de gebruiker 'defaultuser0' is (OOBE), en voert dan Windows Updates uit.
        Werkt ook buiten OOBE, maar dan zonder gebruikerscheck.
    .NOTES
        Novoferm Nederland BV
    #>
    [CmdletBinding()]
    param (
        [switch]$Force   # Laat de update altijd uitvoeren, ook buiten OOBE
    )

    # Check OOBE gebruiker, tenzij Force is opgegeven
    if (-not $Force) {
        if ($env:UserName -ne 'defaultuser0') {
            Write-Host "Niet in OOBE-modus. Gebruik -Force om toch updates uit te voeren."
            return
        }
    }

    Write-Host -ForegroundColor Cyan 'Windows Updates uitvoeren...'

    # Installeer PSWindowsUpdate indien nodig
    if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
        try {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            Install-Module PSWindowsUpdate -Force -Confirm:$false
            Import-Module PSWindowsUpdate -Force
        }
        catch {
            Write-Warning 'Kan PSWindowsUpdate niet installeren.'
            return
        }
    }

    # Controleer opnieuw of module beschikbaar is
    if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
        Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Preview' -NotKBArticleID 'KB890830','KB5005463','KB4481252'" -Wait
    }
    else {
        Write-Warning "PSWindowsUpdate-module niet beschikbaar, updates worden overgeslagen."
    }
}
