function OSDCloudLogic {
    #================================================
    #   [PreOS] Update Module
    #================================================
# TLS 1.2 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Installeer de OSD-module (alleen buiten WinPE)
if ($env:SystemDrive -ne "X:") {
    Write-Host -ForegroundColor Green "Buiten WinPE gedetecteerd – OSD-module wordt geïnstalleerd"
    Install-Module -Name OSD -Force -Scope CurrentUser
} else {
    Write-Host -ForegroundColor Yellow "WinPE gedetecteerd – Install-Module wordt overgeslagen"
}

# Importeer de OSD-module
try {
    Write-Host -ForegroundColor Green "Importeren van OSD PowerShell Module..."
    Import-Module -Name OSD -Force -ErrorAction Stop
    Write-Host -ForegroundColor Green "OSD-module succesvol geïmporteerd"
}
catch {
    Write-Host -ForegroundColor Red "Fout bij het importeren van de OSD-module: $_"
    exit 1
}


    #=======================================================================
    #   [OS] Params and Start-OSDCloud
    #=======================================================================
    Write-Host -ForegroundColor Cyan "Set the Global Variables for a Driver Pack name --> none"
    if (((Get-MyComputerModel) -like 'Virtual*') -or ((Get-MyComputerModel) -like 'VMware*')) {
        Write-Host -ForegroundColor Cyan "Set the Global Variables for virtual machines"
        $Global:MyOSDCloud = @{
            DriverPackName = 'none'
            SkipRecoveryPartition = $true
        }
    }
    else {
        $Global:MyOSDCloud = @{
            DriverPackName = 'none'
        }
    }
    
    $Params = @{
        OSVersion = "Windows 11"
        OSBuild = "24H2"
        OSEdition = "Pro"
        OSLanguage = "nl-nl"
        ZTI = $true
        Firmware = $false
    }
    Start-OSDCloud @Params

 Write-Host -ForegroundColor Green "Downloading and creating script for OOBE phase"
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/refs/heads/main/Dev/Remove-AppX.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force

$OOBECMD = @'
@echo off
# Execute OOBE Tasks
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -F C:\Windows\Setup\scripts\Remove-AppX.ps1

# Below a PS session for debug and testing in system context, # when not needed 
# start /wait powershell.exe -NoL -ExecutionPolicy Bypass

exit 
'@
    $OOBE | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force

    #================================================
    #  [PostOS] SetupComplete CMD Command Line
    #================================================
    Write-Host -ForegroundColor Cyan "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
    $SetupCompleteCMD = @'
'@
    $SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Width 2000 -Force

    #=======================================================================
    #  [PostOS] Params and Start-OSDCloud
    #=======================================================================
    If((Get-MyComputerManufacturer) -like "*Microsoft*") {								
        Write-Host -ForegroundColor Cyan "Device manufacturer is Microsoft Corporation --> need to download some drivers"
        $Get_Product_Info = (Get-MyComputerProduct)

        Write-Host -ForegroundColor Gray "Getting OSDCloudDriverPackage for this $Get_Product_Info"
        $DriverPack = Get-OSDCloudDriverPacks | Where-Object {($_.Product -contains $Get_Product_Info) -and ($_.OS -match $Params.OSVersion)}
        
        if ($DriverPack) {
            [System.String]$DownloadPath = 'C:\Drivers'
            if (-NOT (Test-Path "$DownloadPath")) {
                New-Item $DownloadPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }

            $OutFile = Join-Path $DownloadPath $DriverPack.FileName

            Write-Host -ForegroundColor Cyan "ReleaseDate: $($DriverPack.ReleaseDate)"
            Write-Host -ForegroundColor Cyan "Name: $($DriverPack.Name)"
            Write-Host -ForegroundColor Cyan "Product: $($DriverPack.Product)"
            Write-Host -ForegroundColor Cyan "Url: $($DriverPack.Url)"
            if ($DriverPack.HashMD5) {
                Write-Host -ForegroundColor Cyan "HashMD5: $($DriverPack.HashMD5)"
            }
            Write-Host -ForegroundColor Cyan "OutFile: $OutFile"

            Save-WebFile -SourceUrl $DriverPack.Url -DestinationDirectory $DownloadPath -DestinationName $DriverPack.FileName

            if (! (Test-Path $OutFile)) {
                Write-Warning "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Driver Pack failed to download"
            }

            $DriverPack | ConvertTo-Json | Out-File "$OutFile.json" -Encoding ascii -Width 2000 -Force
        }
    }

    #=======================================================================
    #   Dump some variables
    #=======================================================================
    $Global:OSDCloud | Out-File C:\OSDCloud\Logs\OSDCloud_Variables.log -Force
    $Global:OSDCloud.DriverPack | Out-File C:\OSDCloud\Logs\OSDCloud_DriverPack_Variables.log -Force

    #=======================================================================
    #   Restart-Computer
    #=======================================================================
    Write-Host -ForegroundColor Cyan "Restarting in 20 seconds!"
    Start-Sleep -Seconds 20
    wpeutil reboot
}
