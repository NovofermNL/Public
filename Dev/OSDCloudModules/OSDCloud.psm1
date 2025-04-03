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

    #================================================
    #  [PostOS] OOBEDeploy Configuration
    #================================================
    Write-Host -ForegroundColor Cyan "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
    $OOBEDeployJson = @'
    {
        "Autopilot":  {
                        "IsPresent":  false
                    },
        "RemoveAppx":  [
                        "Microsoft.549981C3F5F10",
                        "Microsoft.BingWeather",
                        "Microsoft.GetHelp",
                        "Microsoft.Getstarted",
                        "Microsoft.Microsoft3DViewer",
                        "Microsoft.MicrosoftOfficeHub",
                        "Microsoft.MicrosoftSolitaireCollection",
                        "Microsoft.MixedReality.Portal",
                        "Microsoft.Office.OneNote",
                        "Microsoft.People",
                        "Microsoft.SkypeApp",
                        "Microsoft.Wallet",
                        "Microsoft.WindowsCamera",
                        "microsoft.windowscommunicationsapps",
                        "Microsoft.WindowsFeedbackHub",
                        "Microsoft.WindowsMaps",
                        "Microsoft.Xbox.TCUI",
                        "Microsoft.XboxApp",
                        "Microsoft.XboxGameOverlay",
                        "Microsoft.XboxGamingOverlay",
                        "Microsoft.XboxIdentityProvider",
                        "Microsoft.XboxSpeechToTextOverlay",
                        "Microsoft.YourPhone",
                        "Microsoft.ZuneMusic",
                        "Microsoft.ZuneVideo"
                    ],
        "UpdateDrivers":  {
                            "IsPresent":  false
                        },
        "UpdateWindows":  {
                            "IsPresent":  false
                        }
    }
'@
    If (!(Test-Path "C:\ProgramData\OSDeploy")) {
        New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
    }
    $OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

    #================================================
    #  [PostOS] AutopilotOOBE Configuration Staging
    #================================================
    Write-Host -ForegroundColor Cyan "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
    Write-Host -ForegroundColor Gray "Define Computername"
    $Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
    $AssignedComputerName = $Serial.Substring(0,9)
    Write-Host -ForegroundColor Green $AssignedComputerName

    $AutopilotOOBEJson = @"
    {
        "Assign":  {
                        "IsPresent":  false
                    },
        "GroupTag":  "$AssignedComputerName",
        "AddToGroup": "GroupX",
        "Hidden":  [
                        "AssignedComputerName",
                        "AssignedUser",
                        "PostAction",
                        "Assign"
                    ],
        "PostAction":  "Quit",
        "Run":  "NetworkingWireless",
        "Docs":  "https://google.com/",
        "Title":  "Manual Autopilot Register"
    }
"@
    If (!(Test-Path "C:\ProgramData\OSDeploy")) {
        New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
    }
    $AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force 
    
    #================================================
    #  [PostOS] AutopilotOOBE CMD Command Line
    #================================================
    Write-Host -ForegroundColor Cyan "Create C:\Windows\System32\OOBE.cmd"
    $OOBE = @'
PowerShell -NoLogo -Command Set-ExecutionPolicy Unrestricted -Force
Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
Start /Wait PowerShell -NoLogo -Command Install-Module OSD -Force
::Start /Wait PowerShell -NoLogo -Command Install-Module AutopilotOOBE -Force
Start /Wait PowerShell -NoLogo -CommandInvoke-WebPSScript https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Set-KeyboardLang.ps1
Start /Wait PowerShell -NoLogo -Command Start-OOBEDeploy
Start /Wait PowerShell -NoLogo -Command Remove-AppxOnline /?
::Start /Wait PowerShell -NoLogo -Command Invoke-WebPSScript https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSD-CleanUp.ps1
Start /Wait PowerShell -NoLogo -Command Restart-Computer -Force
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
