# Create local updater dir
$repoBase = "https://raw.githubusercontent.com/craftingedu/minecraft-pack/main"
$updaterDir = "$env:USERPROFILE\minecraft-updater"
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

# Extract crafting.zip to Prism Launcher instances/crafting, overwriting files if needed
$craftingDest = Join-Path $env:APPDATA "PrismLauncher\instances\crafting"
$tempExtract = Join-Path $updaterDir "crafting-temp"
if (Test-Path $tempExtract) {
    Remove-Item -Path $tempExtract -Recurse -Force
}
New-Item -ItemType Directory -Path $tempExtract | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($profileZipPath, $tempExtract)
Copy-Item -Path (Join-Path $tempExtract '*') -Destination $craftingDest -Recurse -Force
Remove-Item -Path $tempExtract -Recurse -Force

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
