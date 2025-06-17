# === CONFIG ===
$repoBase = "https://raw.githubusercontent.com/youruser/minecraft-pack/main"
$updaterDir = "$env:USERPROFILE\minecraft-updater"
$prismDataDir = "$env:APPDATA\.prismlauncher"
$accountsFileUrl = "$repoBase\accounts.json"
$feriumTomlUrl = "$repoBase\ferium.toml"
$modsTomlUrl = "$repoBase\mods.toml"
$updateBatUrl = "$repoBase\update.bat"

# === Step 1: Create local updater dir ===
if (!(Test-Path $updaterDir)) {
    New-Item -ItemType Directory -Path $updaterDir | Out-Null
}

# === Step 2: Install Ferium ===
$feriumPath = "$env:USERPROFILE\.cargo\bin\ferium.exe"
if (!(Test-Path $feriumPath)) {
    Write-Host "Installing Ferium using winget..."
    winget install --id GorillaDevs.Ferium -e --accept-source-agreements --accept-package-agreements
}

# === Step 3: Install Prism Launcher if missing ===
$prismExe = "$env:LOCALAPPDATA\Programs\PrismLauncher\prismlauncher.exe"
if (!(Test-Path $prismExe)) {
    Write-Host "Installing Prism Launcher using winget..."
    winget install --exact PrismLauncher.PrismLauncher --accept-source-agreements --accept-package-agreements
}

# === Step 4: Download required files ===
Invoke-WebRequest -Uri $feriumTomlUrl -OutFile "$updaterDir\ferium.toml"
Invoke-WebRequest -Uri $modsTomlUrl -OutFile "$updaterDir\mods.toml"
Invoke-WebRequest -Uri $updateBatUrl -OutFile "$updaterDir\update.bat"

# === Step 5: Set up Prism Launcher accounts ===
$accountsDir = "$env:APPDATA\PrismLauncher\accounts"
if (!(Test-Path $accountsDir)) {
    New-Item -ItemType Directory -Path $accountsDir | Out-Null
}
Invoke-WebRequest -Uri $accountsFileUrl -OutFile "$accountsDir\accounts.json"

# === Step 5.5: Import Prism Launcher profile ===
$profileZipUrl = "$repoBase\crafting.zip"
$profileZipPath = "$updaterDir\crafting.zip"
$instancesDir = "$prismDataDir\instances"
if (!(Test-Path $instancesDir)) {
    New-Item -ItemType Directory -Path $instancesDir | Out-Null
}
Invoke-WebRequest -Uri $profileZipUrl -OutFile $profileZipPath
Expand-Archive -Path $profileZipPath -DestinationPath $instancesDir -Force

# === Step 6: Create scheduled task ===
$taskName = "Minecraft Mod Auto-Updater"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (!$taskExists) {
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c $updaterDir\update.bat"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -RunLevel Highest -Force
}

# === Step 7: Run updater immediately ===
Start-Process "cmd.exe" "/c $updaterDir\update.bat"
