<#
.SYNOPSIS
Installeert alle beschikbare Windows-updates via PSWindowsUpdate.

.BY
Novoferm Nederland BV

.DATE
25-04-2025

#>

# =========================================
# Basisinstellingen
# =========================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-Transcript -Path "C:\Windows\Temp\Install-WindowsUpdate.log"

# =========================================
# Zorg dat NuGet en PowerShellGet werken
# =========================================

Write-Host "Controleren of NuGet provider beschikbaar is..."
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers
        Write-Host "NuGet provider is geïnstalleerd."
    } catch {
        Write-Warning "Installatie van NuGet-provider mislukt: $_"
    }
}

Write-Host "Controleren of PowerShell Gallery vertrouwd is..."
try {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction Stop
    Write-Host "PSGallery repository ingesteld als Trusted."
} catch {
    Write-Warning "Kon PSGallery niet instellen als Trusted: $_"
}

Write-Host "Controleren of PowerShellGet geladen is..."
try {
    Import-Module PowerShellGet -Force -ErrorAction Stop
    Write-Host "PowerShellGet is geladen."
} catch {
    Write-Warning "PowerShellGet kon niet worden geladen: $_"
}

# =========================================
# Functie: Installeer PSWindowsUpdate
# =========================================

function Ensure-PSWindowsUpdate {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        try {
            Write-Host "PSWindowsUpdate wordt geïnstalleerd..."
            Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers
        } catch {
            Write-Warning "Fout bij installeren van PSWindowsUpdate: $_"
        }
    } else {
        Write-Host "PSWindowsUpdate is al aanwezig."
    }

    try {
        Import-Module PSWindowsUpdate -Force -ErrorAction Stop
        Write-Host "PSWindowsUpdate is geladen."
    } catch {
        Write-Warning "Fout bij laden van PSWindowsUpdate: $_"
    }
}

# =========================================
# Functie: Installeer updates
# =========================================

function Install-WindowsUpdates {
    try {
        Write-Host "Zoeken naar updates..."
        Get-WindowsUpdate -AcceptAll -Install -AutoReboot -Verbose
    } catch {
        Write-Warning "Fout bij installeren van updates: $_"
    }
}

# =========================================
# Main
# =========================================

Ensure-PSWindowsUpdate
Install-WindowsUpdates

Stop-Transcript
