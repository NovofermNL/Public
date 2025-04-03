Write-Host -ForegroundColor Green "Installeren van de  OSDCloudLogic Module"
New-Item -Path "X:\Program Files\WindowsPowerShell\Modules\OSDCloudLogic" -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/NovofermNL/Public/main/Dev/OSDCloudModules/OSDCloud.psm1" -OutFile "X:\Program Files\WindowsPowerShell\Modules\OSDCloudLogic\OSDCloudLogic.psm1"
Import-Module OSDCloudLogic.psm1 -Force

Write-Host -ForegroundColor Green "Starting OSDClou"
OSDCloudLogic -ComputerPrefix "NL"
