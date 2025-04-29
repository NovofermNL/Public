#================================================
#   [PreOS] Update Module
#================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   

Write-Host -ForegroundColor Green "Downloaden van benodigde files"



#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSVersion = "Windows 11"
    OSBuild = "24H2"
    OSEdition = "Pro"
    OSLanguage = "ml-nl"
    OSLicense = "Retail"
    ZTI = $true
}
Start-OSDCloud @Params

# Definieer Add-Capability functie
function osdcloud-AddCapability {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory,ParameterSetName='ByName',Position=0)]
        [System.String[]]$Name
    )
    if ($Name) {
        #Do Nothing
    }
    else {
        $Name = Get-WindowsCapability -Online -ErrorAction SilentlyContinue | Where-Object {$_.State -ne 'Installed'} | Select-Object Name | Out-GridView -PassThru -Title 'Select one or more Capabilities' | Select-Object -ExpandProperty Name
    }
    if ($Name) {
        Write-Host -ForegroundColor Cyan "Add-WindowsCapability -Online"
        foreach ($Item in $Name) {
            $WindowsCapability = Get-WindowsCapability -Online -Name "*$Item*" -ErrorAction SilentlyContinue | Where-Object {$_.State -ne 'Installed'}
            if ($WindowsCapability) {
                foreach ($Capability in $WindowsCapability) {
                    Write-Host -ForegroundColor DarkGray $Capability.DisplayName
                    $Capability | Add-WindowsCapability -Online | Out-Null
                }
            }
        }
    }
}

# Maak alias
New-Alias -Name 'Add-Capability' -Value 'osdcloud-AddCapability' -Description 'OSDCloud' -Force

# Voer Add-Capability uit om NetFx te installeren
Add-Capability -Name 'NetFx'


# Definieer RemoveAppx functie
function osdcloud-RemoveAppx {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory,ParameterSetName='Basic')]
        [System.Management.Automation.SwitchParameter]$Basic,

        [Parameter(Mandatory,ParameterSetName='ByName',Position=0)]
        [System.String[]]$Name
    )
    if (Get-Command Get-AppxProvisionedPackage) {
        if ($Basic) {
            $Name = @('CommunicationsApps','OfficeHub','People','Skype','Solitaire','Xbox','ZuneMusic','ZuneVideo')
        }
        elseif (-not $Name) {
            $Name = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Select-Object -Property DisplayName | Out-GridView -PassThru -Title 'Select one or more Appx Provisioned Packages to remove' | Select-Object -ExpandProperty DisplayName
        }
        if ($Name) {
            Write-Host -ForegroundColor Cyan 'Removing Appx Provisioned Packages...'
            foreach ($Item in $Name) {
                Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -match $Item} | ForEach-Object {
                    Write-Host -ForegroundColor DarkGray $_.DisplayName
                    try {
                        if ((Get-Command Remove-AppxProvisionedPackage).Parameters.ContainsKey('AllUsers')) {
                            Remove-AppxProvisionedPackage -Online -AllUsers -PackageName $_.PackageName -ErrorAction SilentlyContinue
                        } else {
                            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
                        }
                    }
                    catch {
                        Write-Warning "Failed to remove Appx package: $($_.PackageName)"
                    }
                }
            }
        }
    }
}

# Maak alias RemoveAppx aan
New-Alias -Name 'RemoveAppx' -Value 'osdcloud-RemoveAppx' -Description 'OSDCloud' -Force

#verwijder de standaard Microsoft apps (basic set)
RemoveAppx -Basic

Invoke-WebRequest -Uri "https://github.com/NovofermNL/Public/raw/main/Prod/start2.bin" -OutFile "C:\Windows\Setup\scripts\start2.bin"
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSDCloudModules/Copy-Start.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Copy-Start.ps1' -Encoding ascii -Force
Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Prod/OSDCleanUp.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\OSDCleanUp.ps1' -Encoding ascii -Force

# Download scripts
#Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/Remove-AppX.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\Remove-AppX.ps1' -Encoding ascii -Force
#Invoke-RestMethod https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OOBE.ps1 | Out-File -FilePath 'C:\Windows\Setup\scripts\OOBE.ps1' -Encoding ascii -Force

# Zet hash upload scripts klaar
#Copy-Item "X:\OSDCloud\Config\Run-Autopilot-Hash-Upload.cmd" -Destination "C:\Windows\System32\" -Force
#Copy-Item "X:\OSDCloud\Config\Autopilot-Hash-Upload.ps1" -Destination "C:\Windows\System32\" -Force

$OOBECMD = @'
@echo off
:: OOBE fase – verwijder standaard apps
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Remove-AppX.ps1
:: OOBE fase – Aanpassen Start Menu
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\Copy-Start.ps1
start /wait powershell.exe -NoLogo -ExecutionPolicy Bypass -File C:\Windows\Setup\scripts\OSDCleanUp.ps1"
'@

$OOBECMD | Out-File -FilePath 'C:\Windows\Setup\scripts\oobe.cmd' -Encoding ascii -Force

# SetupComplete – wordt uitgevoerd vóór eerste login
$SetupComplete = @'

'@

$SetupComplete | Out-File -FilePath 'C:\Windows\Setup\scripts\SetupComplete.cmd' -Encoding ascii -Force


#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host "Restarting in 20 seconds!" -ForegroundColor Green
Start-Sleep -Seconds 20
#wpeutil reboot
