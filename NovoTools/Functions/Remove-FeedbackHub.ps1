#Requires -RunAsAdministrator
<#
Scriptnaam    : Remove-FeedbackHub.ps1
Beschrijving  : Verwijdert Feedback Hub voor bestaande én nieuwe gebruikers. Functie-only, met -WhatIf/-Confirm.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Remove-FeedbackHub {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param(
        [switch]$NoTranscript
    )

    $ScriptName = 'Remove-FeedbackHub'
    $Today      = (Get-Date).ToString('dd-MM-yyyy')
    $LogRoot    = 'C:\Windows\Temp\Remove-FeedbackHub'
    $LogFile    = Join-Path $LogRoot ("{0}_{1}.log" -f $ScriptName,$Today)

    $ErrorActionPreference = 'Stop'
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
    if (-not $NoTranscript) { try { Start-Transcript -Path $LogFile -Append -ErrorAction Stop } catch { } }

    try {
        # 1) Provisioned (voor nieuwe profielen)
        $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*WindowsFeedbackHub*' }
        foreach ($p in $prov) {
            if ($PSCmdlet.ShouldProcess($p.PackageName, 'Remove-AppxProvisionedPackage -Online')) {
                Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName | Out-Null
            }
        }

        # 2) Installed (AllUsers)
        $pkg = Get-AppxPackage -AllUsers -Name 'Microsoft.WindowsFeedbackHub'
        foreach ($p in $pkg) {
            if ($PSCmdlet.ShouldProcess($p.PackageFullName, 'Remove-AppxPackage -AllUsers')) {
                try { Remove-AppxPackage -AllUsers -Package $p.PackageFullName }
                catch { Write-Warning "Remove-AppxPackage -AllUsers faalde voor $($p.PackageFullName): $($_.Exception.Message)" }
            }
        }

        # 3) Restanten per user (map)
        $userRoots = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notin @('Public','Default','Default User','All Users')
        }
        foreach ($u in $userRoots) {
            $pkgPath = Join-Path $u.FullName 'AppData\Local\Packages\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe'
            if (Test-Path $pkgPath -PathType Container) {
                if ($PSCmdlet.ShouldProcess("$($u.Name): $pkgPath", 'Remove-Item -Recurse -Force')) {
                    Remove-Item -LiteralPath $pkgPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        # 4) Startmenu-snelkoppelingen (common)
        $commonStart = "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs"
        foreach ($lnk in @('Feedback Hub.lnk','Windows Feedback.lnk')) {
            $path = Join-Path $commonStart $lnk
            if (Test-Path $path) {
                if ($PSCmdlet.ShouldProcess($path, 'Remove-Item -Force')) {
                    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
                }
            }
        }

        # 5) Policy om herinstallatie/consumentenfeatures te blokkeren
        $ccKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
        if (-not (Test-Path $ccKey)) { New-Item -Path $ccKey -Force | Out-Null }
        New-ItemProperty -Path $ccKey -Name 'DisableWindowsConsumerFeatures' -Value 1 -PropertyType DWord -Force | Out-Null

        $feKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
        if (-not (Test-Path $feKey)) { New-Item -Path $feKey -Force | Out-Null }
        New-ItemProperty -Path $feKey -Name 'DoNotShowFeedbackNotifications' -Value 1 -PropertyType DWord -Force | Out-Null

        return $true
    }
    catch {
        Write-Error "Er is een fout opgetreden: $($_.Exception.Message)"
        return $false
    }
    finally {
        if (-not $NoTranscript) { try { Stop-Transcript | Out-Null } catch { } }
    }
}
