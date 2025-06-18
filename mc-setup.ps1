# Create local updater dir
$repoBase = "https://raw.githubusercontent.com/craftingedu/minecraft-pack/main"
$updaterDir = "$env:USERPROFILE\minecraft-updater"
$accountsFileUrl = "$repoBase\accounts.json"
$updateBatUrl = "$repoBase\update.bat"

Write-Host "Updater directory path: $updaterDir" -ForegroundColor Cyan
if (!(Test-Path $updaterDir)) {
    Write-Host "Creating updater directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $updaterDir | Out-Null
    Write-Host "Updater directory created." -ForegroundColor Green
}
else {
    Write-Host "Updater directory already exists." -ForegroundColor Green
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
Write-Host "Downloading profile zip from: $profileZipUrl" -ForegroundColor Cyan
Write-Host "Saving profile zip to: $profileZipPath" -ForegroundColor Cyan
Invoke-WebRequest -Uri $profileZipUrl -OutFile $profileZipPath
Write-Host "Profile zip downloaded successfully." -ForegroundColor Green

# Extract crafting.zip to Prism Launcher instances/crafting, replacing files if needed
$craftingDest = Join-Path $env:APPDATA "PrismLauncher\instances\crafting"
Write-Host "Crafting destination directory: $craftingDest" -ForegroundColor Cyan
if (Test-Path $craftingDest) {
    Write-Host "Destination directory exists, removing..." -ForegroundColor Yellow
    Remove-Item -Path $craftingDest -Recurse -Force
    Write-Host "Existing directory removed." -ForegroundColor Green
}
else {
    Write-Host "Destination directory does not exist." -ForegroundColor Yellow
}

Write-Host "Creating fresh destination directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $craftingDest | Out-Null
Write-Host "Directory created." -ForegroundColor Green

# Use Expand-Archive instead of ZipFile::ExtractToDirectory
Write-Host "Extracting archive from $profileZipPath to $craftingDest" -ForegroundColor Yellow
try {
    Expand-Archive -Path $profileZipPath -DestinationPath $craftingDest -Force
    Write-Host "Archive extracted successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error extracting archive: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_)" -ForegroundColor Red
}

# Set up Prism Launcher accounts
$accountsJsonPath = "$env:APPDATA\PrismLauncher\accounts.json"
Write-Host "Setting up Prism Launcher accounts at: $accountsJsonPath" -ForegroundColor Cyan
Invoke-WebRequest -Uri $accountsFileUrl -OutFile $accountsJsonPath
Write-Host "Accounts configuration complete." -ForegroundColor Green

# Install Ferium
$feriumPath = "$env:USERPROFILE\.cargo\bin\ferium.exe"
Write-Host "Checking for Ferium at: $feriumPath" -ForegroundColor Cyan
if (!(Test-Path $feriumPath)) {
    Write-Host "Ferium not found. Installing Ferium using winget..." -ForegroundColor Yellow
    winget install --id GorillaDevs.Ferium -e --accept-source-agreements --accept-package-agreements
    Write-Host "Ferium installation complete." -ForegroundColor Green
}
else {
    Write-Host "Ferium already installed." -ForegroundColor Green
}

# Download required files
$updateBatPath = "$updaterDir\update.bat"
Write-Host "Downloading update script from: $updateBatUrl" -ForegroundColor Cyan
Write-Host "Saving to: $updateBatPath" -ForegroundColor Cyan
Invoke-WebRequest -Uri $updateBatUrl -OutFile $updateBatPath
Write-Host "Update script downloaded." -ForegroundColor Green

# Create scheduled task
$taskName = "Minecraft Mod Auto-Updater"
Write-Host "Setting up scheduled task: $taskName" -ForegroundColor Cyan
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (!$taskExists) {
    Write-Host "Task does not exist, creating new task..." -ForegroundColor Yellow
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c $updaterDir\update.bat"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -RunLevel Highest -Force
    Write-Host "Scheduled task created with admin privileges." -ForegroundColor Green
}
else {
    Write-Host "Task already exists." -ForegroundColor Green
}

# Run updater immediately
Write-Host "Running update script immediately..." -ForegroundColor Cyan
Start-Process "cmd.exe" "/c $updaterDir\update.bat"
Write-Host "Setup complete!" -ForegroundColor Green
