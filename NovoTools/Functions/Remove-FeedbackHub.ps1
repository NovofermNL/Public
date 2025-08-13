#Requires -RunAsAdministrator
<#
Scriptnaam    : Remove-FeedbackHub.ps1
Datum         : 13-08-2025
Beschrijving  : Verwijdert Feedback Hub (Microsoft.WindowsFeedbackHub) voor bestaande én nieuwe gebruikers
                (Server/Windows 11). Ontworpen als FUNCTIE voor import in een module.
Organisatie   : Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Remove-FeedbackHub {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [switch]$NoTranscript  # handig voor unit tests of als transcript niet gewenst is
    )

    #----- Basisinstellingen
    $ScriptName = 'Remove-FeedbackHub'
    $Today      = (Get-Date).ToString('dd-MM-yyyy')
    $LogRoot    = 'C:\Windows\Temp\Remove-FeedbackHub'
    $LogFile    = Join-Path $LogRoot ("{0}_{1}.log" -f $ScriptName,$Today)

    $ErrorActionPreference = 'Stop'
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null

    if (-not $NoTranscript) {
        try { Start-Transcript -Path $LogFile -Append -ErrorAction Stop } catch { }
    }

    Write-Verbose "[$ScriptName] Start: $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')"

    #----- Helpers (lokaal binnen de functie)
    function _RemoveProvisioned {
        Write-Verbose "Zoek/verwijder provisioned package(s) ..."
        $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*WindowsFeedbackHub*' }
        if ($prov) {
            foreach ($p in $prov) {
                if ($PSCmdlet.ShouldProcess($p.PackageName, 'Remove-AppxProvisionedPackage -Online')) {
                    Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName | Out-Null
                }
            }
        } else {
            Write-Verbose "Geen provisioned Feedback Hub gevonden."
        }
    }

    function _RemoveAllUsers {
        Write-Verbose "Zoek/verwijder geïnstalleerde app voor alle gebruikers ..."
        $pkg = Get-AppxPackage -AllUsers -Name 'Microsoft.WindowsFeedbackHub'
        if ($pkg) {
            foreach ($p in $pkg) {
                if ($PSCmdlet.ShouldProcess($p.PackageFullName, 'Remove-AppxPackage -AllUsers')) {
                    try {
                        Remove-AppxPackage -AllUsers -Package $p.PackageFullName
                    } catch {
                        Write-Warning "Remove-AppxPackage -AllUsers faalde voor $($p.PackageFullName): $($_.Exception.Message)"
                    }
                }
            }
        } else {
            Write-Verbose "Geen geïnstalleerde Feedback Hub pakketten gevonden bij AllUsers."
        }
    }

    function _ClearPerUserResiduals {
        Write-Verbose "Opschonen per-user restanten ..."
        $userRoots = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notin @('Public','Default','Default User','All Users') -and
            (Test-Path (Join-Path $_.FullName 'AppData\Local\Packages'))
        }

        foreach ($u in $userRoots) {
            $pkgPath = Join-Path $u.FullName 'AppData\Local\Packages\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe'
            if (Test-Path $pkgPath) {
                if ($PSCmdlet.ShouldProcess("$($u.Name): $pkgPath", 'Remove residual package folder')) {
                    try {
                        Remove-Item -LiteralPath $pkgPath -Recurse -Force -ErrorAction SilentlyContinue
                    } catch {
                        Write-Warning "Opschonen bij $($u.Name) gaf een fout: $($_.Exception.Message)"
                    }
                }
            }
        }
    }

    function _RemoveStartMenuShortcuts {
        Write-Verbose "Verwijderen Startmenu-snelkoppeling (gemeenschappelijk) ..."
        $commonStart = "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs"
        foreach ($lnk in @('Feedback Hub.lnk','Windows Feedback.lnk')) {
            $path = Join-Path $commonStart $lnk
            if (Test-Path $path) {
                if ($PSCmdlet.ShouldProcess($path, 'Remove-Item')) {
                    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    function _SetBlockReinstallPolicy {
        Write-Verbose "Instellen policy om herinstallaties/feedback prompts te beperken ..."
        $ccKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
        if (-not (Test-Path $ccKey)) { New-Item -Path $ccKey -Force | Out-Null }
        New-ItemProperty -Path $ccKey -Name 'DisableWindowsConsumerFeatures' -Value 1 -PropertyType DWord -Force | Out-Null

        $feKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
        if (-not (Test-Path $feKey)) { New-Item -Path $feKey -Force | Out-Null }
        New-ItemProperty -Path $feKey -Name 'DoNotShowFeedbackNotifications' -Value 1 -PropertyType DWord -Force | Out-Null
    }

    #----- Uitvoering
    $hadError = $false
    try {
        _RemoveProvisioned
        _RemoveAllUsers
        _ClearPerUserResiduals
        _RemoveStartMenuShortcuts
        _SetBlockReinstallPolicy

        Write-Verbose "Klaar. Herstart aangeraden om shell-caches te verversen."
    }
    catch {
        $hadError = $true
        Write-Error "Er is een fout opgetreden: $($_.Exception.Message)"
    }
    finally {
        Write-Verbose "[$ScriptName] Einde: $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')"
        if (-not $NoTranscript) {
            try { Stop-Transcript | Out-Null } catch { }
        }
    }

    if ($hadError) { return $false } else { return $true }
}
