# === CONFIG ===
$repoBase = "https://raw.githubusercontent.com/youruser/minecraft-pack/main"
$updaterDir = "$env:USERPROFILE\minecraft-updater"
$prismDataDir = "$env:APPDATA\.prismlauncher"
$accountsFileUrl = "$repoBase\accounts.json"
$feriumJsonUrl = "$repoBase\config.json"
$modsTomlUrl = "$repoBase\mods.toml"
$updateBatUrl = "$repoBase\update.bat"

# === Step 1: Create local updater dir ===
if (!(Test-Path $updaterDir)) {
    New-Item -ItemType Directory -Path $updaterDir | Out-Null
}

# === Step 2: Install Prism Launcher if missing (must be before Ferium) ===
$prismExe = "$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe"
if (!(Test-Path $prismExe)) {
    Write-Host "Installing Prism Launcher using winget..."
    winget install --exact PrismLauncher.PrismLauncher --accept-source-agreements --accept-package-agreements
}

# === Step 3: Download and import Prism Launcher profile ===
$profileZipUrl = "$repoBase\crafting.zip"
$profileZipPath = "$updaterDir\crafting.zip"
$instancesDir = "$prismDataDir\instances"
if (!(Test-Path $instancesDir)) {
    New-Item -ItemType Directory -Path $instancesDir | Out-Null
}
Invoke-WebRequest -Uri $profileZipUrl -OutFile $profileZipPath
Expand-Archive -Path $profileZipPath -DestinationPath $instancesDir -Force

# === Step 4: Set up Prism Launcher accounts ===
$accountsDir = "$env:APPDATA\PrismLauncher\accounts"
if (!(Test-Path $accountsDir)) {
    New-Item -ItemType Directory -Path $accountsDir | Out-Null
}
Invoke-WebRequest -Uri $accountsFileUrl -OutFile "$accountsDir\accounts.json"

# === Step 5: Install Ferium ===
if (!(Test-Path "$env:USERPROFILE\.cargo\bin\ferium.exe")) {
    Write-Host "Installing Ferium using winget..."
    winget install --id GorillaDevs.Ferium -e --accept-source-agreements --accept-package-agreements
}

# === Step 6: Place Ferium config ===
$feriumConfigDir = Join-Path $env:USERPROFILE ".config\ferium"
if (!(Test-Path $feriumConfigDir)) {
    New-Item -ItemType Directory -Path $feriumConfigDir | Out-Null
}
Invoke-WebRequest -Uri $feriumJsonUrl -OutFile "$feriumConfigDir\config.json"

# === Step 7: Configure Ferium profile with correct output dir ===
$craftingModsDir = "$env:APPDATA\PrismLauncher\instances\crafting\minecraft\mods"
ferium profile configure --output-dir "$craftingModsDir"

# === Step 8: Download required files ===
Invoke-WebRequest -Uri $feriumJsonUrl -OutFile "$updaterDir\config.json"
Invoke-WebRequest -Uri $modsTomlUrl -OutFile "$updaterDir\mods.toml"
Invoke-WebRequest -Uri $updateBatUrl -OutFile "$updaterDir\update.bat"

# === Step 9: Create scheduled task ===
$taskName = "Minecraft Mod Auto-Updater"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (!$taskExists) {
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c $updaterDir\update.bat"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -RunLevel Highest -Force
}

# === Step 10: Run updater immediately ===
Start-Process "cmd.exe" "/c $updaterDir\update.bat"
