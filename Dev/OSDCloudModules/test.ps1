# TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install and Import OSD Module (skip in WinPE)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Updating OSD PowerShell Module (buiten WinPE)"
    Install-Module OSD -Force
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module OSD wordt overgeslagen"
}

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

# Start installatie van Windows 11
Write-Host -ForegroundColor Cyan "Installatie van Windows 11 wordt gestart..."
Start-OSDCloud -OSName 'Windows 11 24H2 x64' -OSLanguage nl-nl -OSEdition Enterprise -OSActivation Volume


#Regio Variabelen
$appx2remove = @('OneNote','BingWeather','CommunicationsApps','OfficeHub','People','Skype','Solitaire','Xbox','ZuneMusic','ZuneVideo','FeedbackHub','TCUI')
#endregion

        # Start OSDCloud
        Start-OSDCloud -OSLanguage de-de -OSBuild 24H2 -OSEdition Pro -OSLicense Retail -SkipODT -OSVersion 'Windows 11' -ZTI -SkipAutopilot

        #Verwijder APPX
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
