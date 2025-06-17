# Create local updater dir
$repoBase = "https://raw.githubusercontent.com/craftingedu/minecraft-pack/main"
$updaterDir = "$env:USERPROFILE\minecraft-updater"
$prismDataDir = "$env:APPDATA\.prismlauncher"
$accountsFileUrl = "$repoBase\accounts.json"
$updateBatUrl = "$repoBase\update.bat"

if (!(Test-Path $updaterDir)) {
    New-Item -ItemType Directory -Path $updaterDir | Out-Null
}

# Install Prism Launcher if missing (must be before profile import)
$prismExe = "$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe"
if (!(Test-Path $prismExe)) {
    Write-Host "Installing Prism Launcher using winget..."
    winget install --exact PrismLauncher.PrismLauncher --accept-source-agreements --accept-package-agreements
}

# Download Prism Launcher profile zip
$profileZipUrl = "$repoBase\crafting.zip"
$profileZipPath = "$updaterDir\crafting.zip"
Invoke-WebRequest -Uri $profileZipUrl -OutFile $profileZipPath

# Import Prism Launcher instance using prismlauncher -I
$prismInstallDir = "$env:LOCALAPPDATA\Programs\PrismLauncher"
Start-Process -FilePath "$prismInstallDir\prismlauncher.exe" -ArgumentList "-I $profileZipPath" -WorkingDirectory $prismInstallDir -Wait

# Set up Prism Launcher accounts
$accountsJsonPath = "$env:APPDATA\PrismLauncher\accounts.json"
Invoke-WebRequest -Uri $accountsFileUrl -OutFile $accountsJsonPath

# Install Ferium
if (!(Test-Path "$env:USERPROFILE\.cargo\bin\ferium.exe")) {
    Write-Host "Installing Ferium using winget..."
    winget install --id GorillaDevs.Ferium -e --accept-source-agreements --accept-package-agreements
}

# Download required files
Invoke-WebRequest -Uri $updateBatUrl -OutFile "$updaterDir\update.bat"

# Create scheduled task
$taskName = "Minecraft Mod Auto-Updater"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (!$taskExists) {
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c $updaterDir\update.bat"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -RunLevel Highest -Force
}

# Run updater immediately
Start-Process "cmd.exe" "/c $updaterDir\update.bat"
