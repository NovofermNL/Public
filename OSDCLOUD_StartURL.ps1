#Requires -RunAsAdministrator

$Automate = @'
{
    "BrandName":  "Novoferm Nederland",
    "BrandColor":  "RED",
    "OSActivation":  "Volume",
    "OSEdition":  "Enterprise",
    "OSLanguage":  "nl-nl",
    "OSImageIndex":  6,
    "OSName":  "Windows 11 24H2 x64",
    "OSReleaseID":  "24H2",
    "OSVersion":  "Windows 11",
    "OSActivationValues":  [
        "Retail",
        "Volume"
    ],
    "OSEditionValues":  [
        "Enterprise",
        "Pro"
    ],
    "OSLanguageValues":  [
        "nl-nl",
        "en-us"
    ],
    "OSNameValues":  [
        "Windows 11 24H2 x64",
        "Windows 10 22H2 x64"
    ],
    "OSReleaseIDValues":  [
        "24H2"
    ],
    "OSVersionValues":  [
        "Windows 11",
        "Windows 10"
    ],
    "ClearDiskConfirm":  false,
    "restartComputer":  false,
    "updateDiskDrivers":  false,
    "updateFirmware":  false,
    "updateNetworkDrivers":  true,
    "updateSCSIDrivers":  true
}
'@


$AutomateISO = "$(Get-OSDCloudWorkspace)\Media\OSDCloud\Automate"
if (!(Test-Path $AutomateISO)) {
    New-Item -Path $AutomateISO -ItemType Directory -Force
}
$Automate | Out-File -FilePath "$AutomateISO\Start-OSDCloudGUI.json" -Force


$AutomateUSB = "$(Get-OSDCloudWorkspace)\Media\Automate"
if (!(Test-Path $AutomateUSB)) {
    New-Item -Path $AutomateUSB -ItemType Directory -Force
}
$Automate | Out-File -FilePath "$AutomateUSB\Start-OSDCloudGUI.json" -Force

# Run Edit-OSDCloudWinPE to rebuild
Edit-OSDCloudWinPE -StartOSDCloudGUI

# Test in a Virtual Machine
New-OSDCloudVM
