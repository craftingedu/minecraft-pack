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

# Download and import Prism Launcher profile
$profileZipUrl = "$repoBase\crafting.zip"
$profileZipPath = "$updaterDir\crafting.zip"
$instancesDir = "$prismDataDir\instances"
if (!(Test-Path $instancesDir)) {
    New-Item -ItemType Directory -Path $instancesDir | Out-Null
}
Invoke-WebRequest -Uri $profileZipUrl -OutFile $profileZipPath
Expand-Archive -Path $profileZipPath -DestinationPath $instancesDir -Force

# Set up Prism Launcher accounts
$accountsDir = "$env:APPDATA\PrismLauncher\accounts"
if (!(Test-Path $accountsDir)) {
    New-Item -ItemType Directory -Path $accountsDir | Out-Null
}
Invoke-WebRequest -Uri $accountsFileUrl -OutFile "$accountsDir\accounts.json"

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
