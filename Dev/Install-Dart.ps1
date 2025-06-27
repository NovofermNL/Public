$DaRTScriptPath = "$env:TEMP\DaRT.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/osdcloudcline/OSDCloud/main/Extra%20Files/DaRT/DaRT.ps1" -OutFile $DaRTScriptPath
& $DaRTScriptPath
