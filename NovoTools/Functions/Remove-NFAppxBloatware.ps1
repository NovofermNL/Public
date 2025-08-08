function Remove-NFAppxBloatware {
    $apps = @(
        "Microsoft.3DBuilder",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.XboxApp",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo"
    )
    foreach ($app in $apps) {
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
}
