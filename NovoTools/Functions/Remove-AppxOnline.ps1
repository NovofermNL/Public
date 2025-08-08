function Remove-NFAppxOnline {
    [CmdletBinding()]
    Param (
        # Appx-pakketten selecteren in GridView om te verwijderen uit het Windows-image
        [switch]$GridRemoveAppx,

        # Appx-vooraf geïnstalleerde pakketten (Provisioned) selecteren in GridView om te verwijderen uit het Windows-image
        [switch]$GridRemoveAppxPP,

        # Appx-pakketten verwijderen die overeenkomen met de opgegeven naam
        [string[]]$Name
    )

    Begin {
        #===================================================================================================
        # Controleer of script als administrator draait
        #===================================================================================================
        if ((Get-OSDGather -Property IsAdmin) -eq $false) {
            Write-Warning 'Remove-AppxOnline: Deze functie vereist ELEVATED administratorrechten'
            break
        }
    }
    Process {
        #===================================================================================================
        # Ophalen van Windows-versie
        #===================================================================================================
        $GetRegCurrentVersion = Get-RegCurrentVersion

        #===================================================================================================
        # Controleer of OS MajorVersion 10 is
        #===================================================================================================
        if ($GetRegCurrentVersion.CurrentMajorVersionNumber -ne 10) {
            Write-Warning "Remove-AppxOnline: Alleen Windows 10 of hoger wordt ondersteund"
            break
        }

        #===================================================================================================
        # Verwijderen van Appx-pakketten
        #===================================================================================================
        if (Get-Command Get-AppxPackage) {
            if ($GridRemoveAppx.IsPresent) {
                Get-AppxPackage | Where-Object { $_.NonRemovable -ne $true } |
                Out-GridView -PassThru -Title "Selecteer Appx-pakketten om te verwijderen" |
                ForEach-Object {
                    Write-Verbose "$($_.Name): Verwijderen Appx-pakket $($_.PackageFullName)" -Verbose
                    Remove-AppPackage -AllUsers -Package $_.PackageFullName -Verbose
                }
            }
        }

        #===================================================================================================
        # Verwijderen van Appx Provisioned Packages
        #===================================================================================================
        if (Get-Command Get-AppxProvisionedPackage) {
            if ($GridRemoveAppxPP.IsPresent) {
                Get-AppxProvisionedPackage -Online |
                Select-Object DisplayName, PackageName |
                Out-GridView -PassThru -Title "Selecteer Appx Provisioned-pakketten om te verwijderen" |
                ForEach-Object {
                    Write-Verbose "$($_.DisplayName): Verwijderen Appx Provisioned-pakket $($_.PackageName)" -Verbose
                    Remove-AppProvisionedPackage -Online -AllUsers -PackageName $_.PackageName
                }
            }
        }

        #===================================================================================================
        # Verwijderen op basis van naam
        #===================================================================================================
        foreach ($Item in $Name) {
            # Normale Appx-pakketten
            if (Get-Command Get-AppxPackage) {
                $packages = if ((Get-Command Get-AppxPackage).Parameters.ContainsKey('AllUsers')) {
                    Get-AppxPackage -AllUsers | Where-Object { $_.NonRemovable -ne $true -and $_.Name -match $Item }
                } else {
                    Get-AppxPackage | Where-Object { $_.NonRemovable -ne $true -and $_.Name -match $Item }
                }

                foreach ($pkg in $packages) {
                    $params = @{ Package = $pkg.PackageFullName }
                    if ((Get-Command Remove-AppxPackage).Parameters.ContainsKey('AllUsers')) {
                        $params.AllUsers = $true
                    }
                    Write-Verbose "$($pkg.Name): Verwijderen Appx-pakket $($pkg.PackageFullName)" -Verbose
                    try { Remove-AppxPackage @params | Out-Null }
                    catch { Write-Warning "$($pkg.Name): Kon Appx-pakket niet verwijderen" }
                }
            }

            # Provisioned-pakketten
            if (Get-Command Get-AppxProvisionedPackage) {
                Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match $Item } | ForEach-Object {
                    $params = @{ Online = $true; PackageName = $_.PackageName }
                    if ((Get-Command Remove-AppxProvisionedPackage).Parameters.ContainsKey('AllUsers')) {
                        $params.AllUsers = $true
                    }
                    Write-Verbose "$($_.DisplayName): Verwijderen Appx Provisioned-pakket $($_.PackageName)" -Verbose
                    try { Remove-AppProvisionedPackage @params | Out-Null }
                    catch { Write-Warning "$($_.DisplayName): Kon Appx Provisioned-pakket niet verwijderen" }
                }
            }
        }
    }
    End {}
}
