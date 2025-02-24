@ECHO OFF
wpeinit
cd\
title OSD 25.2.12.1
PowerShell -Nol -C Initialize-OSDCloudStartnet
PowerShell -Nol -C Initialize-OSDCloudStartnetUpdate
@ECHO OFF
start PowerShell -NoL
rem Start Autopilot Hash Upload
X:\Windows\System32\Scripts\Autopilot-Hash-Upload.cmd
