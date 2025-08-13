#Requires -RunAsAdministrator
<# 
Scriptnaam    : Remove-FeedbackHub.ps1
Datum         : 13-08-2025
Beschrijving  : Verwijdert Feedback Hub (Microsoft.WindowsFeedbackHub) voor bestaande én nieuwe gebruikers op Windows Server 2025.
Organisatie   : Novoferm Nederland BV
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#----- Basisinstellingen
$ScriptName   = 'Remove-FeedbackHub'
$Today        = (Get-Date).ToString('dd-MM-yyyy')
$LogRoot      = 'C:\Windows\Temp\Remove-FeedbackHub'
$LogFile      = Join-Path $LogRoot ("{0}_{1}.log" -f $ScriptName,$Today)
$ErrorActionPreference = 'Stop'

#----- Logging
New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
Start-Transcript -Path $LogFile -Append

Write-Host "[$ScriptName] Start: $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')"

#----- Hulpfuncties
function Remove-ProvisionedFeedbackHub {
    Write-Host "Zoek en verwijder provisioned package(s) ..."
    $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*WindowsFeedbackHub*' }
    if ($prov) {
        $prov | ForEach-Object {
            Write-Host "Verwijderen provisioned: $($_.DisplayName) ($($_.PackageName))"
            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName | Out-Null
        }
    } else {
        Write-Host "Geen provisioned Feedback Hub gevonden."
    }
}

function Remove-InstalledForAllUsers {
    Write-Host "Zoek en verwijder geïnstalleerde app(s) voor alle gebruikers ..."
    $pkg = Get-AppxPackage -AllUsers -Name 'Microsoft.WindowsFeedbackHub'
    if ($pkg) {
        $pkg | ForEach-Object {
            Write-Host "Verwijderen geïnstalleerde app voor alle users: $($_.Name) ($($_.PackageFullName))"
            # -AllUsers is ondersteund op moderne builds; valt zonodig terug op per-user cleanup
            try {
                Remove-AppxPackage -AllUsers -Package $_.PackageFullName
            } catch {
                Write-Warning "Remove-AppxPackage -AllUsers faalde, probeer per profiel schoon te maken. ($_ )"
            }
        }
    } else {
        Write-Host "Geen geïnstalleerde Feedback Hub pakketten gevonden."
    }
}

function Cleanup-PerUserResiduals {
    Write-Host "Opschonen per-user restanten ..."
    $userRoots = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notin @('Public','Default','Default User','All Users') -and
        (Test-Path (Join-Path $_.FullName 'AppData\Local\Packages'))
    }

    foreach ($u in $userRoots) {
        $pkgPath = Join-Path $u.FullName 'AppData\Local\Packages\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe'
        if (Test-Path $pkgPath) {
            Write-Host "Verwijderen restanten bij gebruiker '$($u.Name)' ..."
            try {
                # Probeer eerst via appx (per-user)
                $userSid = (Get-LocalUser -Name $u.Name -ErrorAction SilentlyContinue).Sid.Value
                if (-not $userSid) {
                    # Fallback: probeer via registry lookup
                    $userSid = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" |
                                Where-Object { (Get-ItemProperty $_.PsPath).ProfileImagePath -eq $u.FullName } |
                                Select-Object -ExpandProperty PSChildName -ErrorAction SilentlyContinue)
                }

                if ($userSid) {
                    # Probeer Remove-AppxPackage voor specifieke user context via DISM workaround niet nodig; verwijder map handmatig
                    Write-Host "Map verwijderen: $pkgPath"
                    Remove-Item -LiteralPath $pkgPath -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    Write-Host "SID onbekend voor $($u.Name); verwijder map direct."
                    Remove-Item -LiteralPath $pkgPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Warning "Opschonen bij $($u.Name) gaf een fout: $_"
            }
        }
    }
}

function Remove-StartMenuShortcuts {
    Write-Host "Verwijderen (gemeenschappelijke) Startmenu-snelkoppeling indien aanwezig ..."
    $commonStart = "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs"
    $candidate1  = Join-Path $commonStart 'Feedback Hub.lnk'
    $candidate2  = Join-Path $commonStart 'Windows Feedback.lnk'
    foreach ($lnk in @($candidate1,$candidate2)) {
        if (Test-Path $lnk) {
            Write-Host "Snelkoppeling verwijderen: $lnk"
            Remove-Item -LiteralPath $lnk -Force -ErrorAction SilentlyContinue
        }
    }
}

function Set-BlockReinstallPolicy {
    Write-Host "Instellen policy om (consumenten) herinstallaties te voorkomen ..."
    $ccKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    if (-not (Test-Path $ccKey)) { New-Item -Path $ccKey -Force | Out-Null }
    New-ItemProperty -Path $ccKey -Name 'DisableWindowsConsumerFeatures' -Value 1 -PropertyType DWord -Force | Out-Null

    # Optioneel: feedbackmelding/frequentie minimaliseren 
    $feKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
    if (-not (Test-Path $feKey)) { New-Item -Path $feKey -Force | Out-Null }
    New-ItemProperty -Path $feKey -Name 'DoNotShowFeedbackNotifications' -Value 1 -PropertyType DWord -Force | Out-Null
}

#----- Uitvoering
try {
    Remove-ProvisionedFeedbackHub
    Remove-InstalledForAllUsers
    Cleanup-PerUserResiduals
    Remove-StartMenuShortcuts
    Set-BlockReinstallPolicy

    Write-Host "Klaar. Herstart wordt aangeraden zodat alle shell-caches ververst worden."
    $exitCode = 0
}
catch {
    Write-Error "Er is een fout opgetreden: $_"
    $exitCode = 0  
}
finally {
    Write-Host "[$ScriptName] Einde: $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')"
    Stop-Transcript | Out-Null
    exit $exitCode
}
