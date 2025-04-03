#Regio Variabelen
$appx2remove = @('OneNote','BingWeather','CommunicationsApps','OfficeHub','People','Skype','Solitaire','Xbox','ZuneMusic','ZuneVideo','FeedbackHub','TCUI')
#endregion

#region Initialiseren
# Bepaal de Windows-fase (bijv. WinPE, OOBE, etc.)
# Schrijf versie en fase naar console
# Invoke-Expression regel is uitgeschakeld
#endregion


        # Start OSDCloud
        Start-OSDCloud -OSLanguage de-de -OSBuild 24H2 -OSEdition Pro -OSLicense Retail -SkipODT -OSVersion 'Windows 11' -ZTI -SkipAutopilot
<#
        ## Download Lenovo P1 driver en kopieer naar driver-map
        $url = "https://download.lenovo.com/..."
        $dest = "c:\Drivers\..."
        Remove-Item -Path c:\Drivers\* -Force -recurse -ErrorAction SilentlyContinue
        Write-Host 'Drivers voor Lenovo P1 worden gedownload. Even geduld...'
        curl.exe $url -o $dest -s
#>
        Verwijder APPX
        Write-Host -ForegroundColor Gray "Even geduld, er wordt opgeruimd..."
        Remove-AppxOnline -name $appx2remove
                        
        # Takenreeks voltooid
        Write-Host -ForegroundColor Green "Alles klaar :-) // Verwijder nu de USB-stick en herstart de PC (sluit alle vensters)."
        pause

        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) OSDCloudRE installatie is voltooid"
    }

    Restart-Computer -force
    $null = Stop-Transcript
}
#endregion
