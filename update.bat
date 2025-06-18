@echo off
setlocal enabledelayedexpansion

REM === Paths ===
set "CONFIG_DIR=%USERPROFILE%\minecraft-updater"

REM === Create folders if needed ===
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

cd /d "%CONFIG_DIR%"

REM === Download latest mod configuration from GitHub ===
curl -L -o config.json https://raw.githubusercontent.com/craftingedu/minecraft-pack/main/config.json

REM === Copy config to Ferium config directory ===
set "FERIUM_CONFIG_DIR=%USERPROFILE%\.config\ferium"
copy /Y config.json "%FERIUM_CONFIG_DIR%\config.json"

REM === Set Ferium output dir variable ===
set "OUTPUT_DIR=%APPDATA%\PrismLauncher\instances\crafting\minecraft\mods"

REM === Configure Ferium profile output dir ===
ferium profile configure --output-dir "%OUTPUT_DIR%"

REM === Download usernameMod.jar into user folder in output dir ===
set "USER_MOD_DIR=%OUTPUT_DIR%\user"
if not exist "%USER_MOD_DIR%" mkdir "%USER_MOD_DIR%"
wget https://github.com/craftingedu/usernameMod/releases/latest/download/usernameMod.jar -O "%USER_MOD_DIR%\usernameMod.jar"

REM === Install/update mods using Ferium ===
ferium upgrade
