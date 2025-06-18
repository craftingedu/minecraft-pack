@echo off
setlocal enabledelayedexpansion

echo === Starting Minecraft Pack Updater ===

REM === Paths ===
echo Setting config directory: %USERPROFILE%\minecraft-updater
set "CONFIG_DIR=%USERPROFILE%\minecraft-updater"

echo Checking/creating config directory...
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

echo Changing to config directory: %CONFIG_DIR%
cd /d "%CONFIG_DIR%"

echo Downloading latest mod configuration from GitHub...
curl -L -o config.json https://raw.githubusercontent.com/craftingedu/minecraft-pack/main/config.json
if errorlevel 1 (
    echo ERROR: Failed to download config.json
    pause
)

echo Copying config.json to Ferium config directory...
set "FERIUM_CONFIG_DIR=%USERPROFILE%\.config\ferium"
copy /Y config.json "%FERIUM_CONFIG_DIR%\config.json"
if errorlevel 1 (
    echo ERROR: Failed to copy config.json
    pause
)

echo Setting Ferium output dir variable...
set "OUTPUT_DIR=%APPDATA%\PrismLauncher\instances\crafting\minecraft\mods"

echo Configuring Ferium profile output dir...
ferium profile configure --output-dir "%OUTPUT_DIR%"
if errorlevel 1 (
    echo ERROR: Ferium profile configure failed
    pause
)

REM === Download usernameMod.jar into user folder in output dir ===
set "USER_MOD_DIR=%OUTPUT_DIR%\user"
if not exist "%USER_MOD_DIR%" mkdir "%USER_MOD_DIR%"
echo Downloading usernameMod.jar to %USER_MOD_DIR%\usernameMod.jar ...
curl -sL -o "%USER_MOD_DIR%\usernameMod.jar" https://github.com/craftingedu/usernameMod/releases/latest/download/usernameMod.jar
if errorlevel 1 (
    echo ERROR: Failed to download usernameMod.jar
    pause
)

REM === Install/update mods using Ferium ===
ferium upgrade
if errorlevel 1 (
    echo ERROR: Ferium upgrade failed
    pause
)

echo === Minecraft Pack Updater Complete ===
