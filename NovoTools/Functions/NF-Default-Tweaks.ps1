function Apply-CustomTweaks {
    Write-Host "Toepassen van aangepaste registerinstellingen en scripts..."

    # Remote Desktop inschakelen
    reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

    # Fast boot uitschakelen
    reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f

    # Edge - FirstRunExperience uitschakelen
    reg.exe add "HKLM\Software\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f

    # USB Selective Suspend uitschakelen
    reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f

    # News and Interests uitschakelen
    reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f

    # Zoekvak op taakbalk verbergen
    reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v SearchOnTaskbarMode /t REG_DWORD /d 0 /f

    # Recommended-sectie in Startmenu verbergen
    reg.exe add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v HideRecommendedSection /t REG_DWORD /d 1 /f

    # Taken automatisch beëindigen voor .DEFAULT gebruiker
    reg.exe add "HKEY_USERS\.DEFAULT\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 1 /f

    # CloudContent optimalisatie uitschakelen
    reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f

    # CEIP uitschakelen
    reg.exe add "HKLM\Software\Policies\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f

    # Autodiscover tweaks voor Outlook 2016
    reg.exe add "HKLM\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover" /v ExcludeHttpsRootDomain /t REG_DWORD /d 1 /f
    #reg.exe add "HKLM\SOFTWARE\Microsoft\Office\16.0\Outlook\AutoDiscover" /v ExcludeExplicitO365Endpoint /t REG_DWORD /d 1 /f

    # Startmenu-pinning script uitvoeren
    $startPinScript = 'C:\Windows\Setup\Scripts\SetStartPins.ps1'
    if (Test-Path $startPinScript) {
        Write-Host "Startmenu pinning uitvoeren..."
        . $startPinScript
    }

    # Visuele effecten uitschakelen
    $regBase = "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects"
    $keys = @(
        "ControlAnimations", "AnimateMinMax", "TaskbarAnimations", "DWMAeroPeekEnabled",
        "MenuAnimation", "TooltipAnimation", "SelectionFade", "DWMSaveThumbnailEnabled",
        "CursorShadow", "ListviewShadow", "ThumbnailsOrIcon", "ListviewAlphaSelect",
        "DragFullWindows", "ComboBoxAnimation", "FontSmoothing", "ListBoxSmoothScrolling",
        "DropShadow"
    )
    foreach ($key in $keys) {
        Set-ItemProperty -Path "$regBase\\$key" -Name 'DefaultValue' -Value 0 -Type DWord -Force
    }

<#
    # Optio#neel extern script uitvoeren
    $extraScript = "C:\\Windows\\Setup\\Scripts\\unattend-01.cmd"
    if (Test-Path $extraScript) {
        Write-Host "Extern script uitvoeren: $extraScript"
        Start-Process -FilePath $extraScript -Wait
    }

    Write-Host "Aangepaste tweaks voltooid."
}
#>
Apply-CustomTweaks
