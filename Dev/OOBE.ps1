[CmdletBinding()]
param()

#region Initialize
$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
$null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

#=================================================
#   oobeCloud Settings
#=================================================
$Global:oobeCloud = @{
    oobeAddCapability           = $true
    oobeAddCapabilityName       = 'NetFX'
    oobeRemoveAppxPackage       = $false
    oobeUpdateDrivers           = $true
    oobeUpdateWindows           = $true
    oobeRestartComputer         = $true
    oobeStopComputer            = $false
}
function Step-oobeExecutionPolicy {
    if ($env:UserName -eq 'defaultuser0') {
        if ((Get-ExecutionPolicy) -ne 'RemoteSigned') {
            Write-Host -ForegroundColor Cyan 'Set-ExecutionPolicy RemoteSigned'
            Set-ExecutionPolicy RemoteSigned -Force
        }
    }
}

function Step-oobePackageManagement {
    if ($env:UserName -eq 'defaultuser0') {
        if (-not (Get-Module -Name PowerShellGet -ListAvailable | Where-Object {$_.Version -ge '2.2.5'})) {
            Write-Host -ForegroundColor Cyan 'Install-Package PowerShellGet'
            Install-Package -Name PowerShellGet -MinimumVersion 2.2.5 -Force -Confirm:$false -Source PSGallery | Out-Null
            Import-Module PackageManagement,PowerShellGet -Force
        }
        else {
            Write-Host -ForegroundColor Cyan 'PowerShellGet 2.2.5 or greater is already installed'
        }
    }
}

function Step-oobeTrustPSGallery {
    if ($env:UserName -eq 'defaultuser0') {
        $PSRepository = Get-PSRepository -Name PSGallery
        if ($PSRepository -and $PSRepository.InstallationPolicy -ne 'Trusted') {
            Write-Host -ForegroundColor Cyan 'Set-PSRepository PSGallery Trusted'
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
    }
}

function Step-oobeAddCapability {
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeAddCapability -eq $true)) {
        Write-Host -ForegroundColor Cyan "Add-WindowsCapability"
        foreach ($Item in $Global:oobeCloud.oobeAddCapabilityName) {
            $WindowsCapability = Get-WindowsCapability -Online -Name "*$Item*" -ErrorAction SilentlyContinue | Where-Object {$_.State -ne 'Installed'}
            foreach ($Capability in $WindowsCapability) {
                Write-Host -ForegroundColor DarkGray $Capability.DisplayName
                $Capability | Add-WindowsCapability -Online | Out-Null
            }
        }
    }
}

function Step-oobeEnsurePSWindowsUpdate {
    $ModuleName = "PSWindowsUpdate"
    $RequiredVersion = [version]'2.2.0.3'

    $installedModule = Get-Module -Name $ModuleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

    if ($installedModule) {
        if ($installedModule.Version -lt $RequiredVersion) {
            Write-Host -ForegroundColor Cyan "$ModuleName versie $($installedModule.Version) is oud, uitvoeren van update..."
            Update-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Host -ForegroundColor Cyan "$ModuleName versie $($installedModule.Version) is up-to-date"
        }
        Import-Module $ModuleName -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Host -ForegroundColor Cyan "$ModuleName is niet geïnstalleerd, installatie wordt gestart..."
        Install-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
        Import-Module $ModuleName -Force -ErrorAction SilentlyContinue
    }
}

function Step-oobeUpdateDrivers {
    $Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer

    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeUpdateDrivers -eq $true)) {
        if ($Manufacturer -match "HP") {
            Write-Host -ForegroundColor Yellow "HP-systeem gedetecteerd – PSWindowsUpdate wordt niet gebruikt voor drivers (afgevangen in Deploy.ps1 via HPCMSL)"
            return
        }

        Write-Host -ForegroundColor Cyan 'Drivers worden bijgewerkt via PSWindowsUpdate'

        Step-oobeEnsurePSWindowsUpdate

        if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
            Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -UpdateType Driver -AcceptAll -IgnoreReboot" -Wait
        }
    }
}

function Step-oobeUpdateWindows {
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeUpdateWindows -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Updating Windows'

        Step-oobeEnsurePSWindowsUpdate

        if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
            Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
            Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Preview' -NotKBArticleID 'KB890830','KB5005463','KB4481252'" -Wait
        }
    }
}
function Step-oobeRemoveAppxPackage {
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeRemoveAppxPackage -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Removing Appx Packages'
        foreach ($Item in $Global:oobeCloud.oobeRemoveAppxPackageName) {
            if (Get-Command Get-AppxProvisionedPackage) {
                Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match $Item} | ForEach-Object {
                    Write-Host -ForegroundColor DarkGray $_.DisplayName
                    if ((Get-Command Remove-AppxProvisionedPackage).Parameters.ContainsKey('AllUsers')) {
                        Try
                        {
                            $null = Remove-AppxProvisionedPackage -Online -AllUsers -PackageName $_.PackageName
                        }
                        Catch
                        {
                            Write-Warning "AllUsers Appx Provisioned Package $($_.PackageName) did not remove successfully"
                        }
                    }
                    else {
                        Try
                        {
                            $null = Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName
                        }
                        Catch
                        {
                            Write-Warning "Appx Provisioned Package $($_.PackageName) did not remove successfully"
                        }
                    }
                }
            }
        }
    }
}
function Step-oobeRestartComputer {
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeRestartComputer -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Build Complete!'
        Write-Warning 'Device will restart in 30 seconds.  Press Ctrl + C to cancel'
        Stop-Transcript
        Start-Sleep -Seconds 30
        Restart-Computer
    }
}

function Step-oobeStopComputer {
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeStopComputer -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Build Complete!'
        Write-Warning 'Device will shutdown in 30 seconds. Press Ctrl + C to cancel'
        Stop-Transcript
        Start-Sleep -Seconds 30
        Stop-Computer
    }
}
#endregion

# Execute functions
Step-oobeExecutionPolicy
Step-oobePackageManagement
Step-oobeTrustPSGallery
Step-oobeAddCapability
Step-oobeUpdateDrivers
Step-oobeUpdateWindows
Step-oobeRestartComputer
Step-oobeStopComputer
