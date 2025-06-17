@echo off
setlocal enabledelayedexpansion

REM === Paths ===
set "CONFIG_DIR=%USERPROFILE%\minecraft-updater"
set "MODS_DIR=%APPDATA%\.prismlauncher\instances\crafting\.minecraft\mods"
set "FERIUM_BIN=%USERPROFILE%\.cargo\bin\ferium.exe"

REM === Create folders if needed ===
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
if not exist "%MODS_DIR%" mkdir "%MODS_DIR%"

cd /d "%CONFIG_DIR%"

REM === Download latest mod configuration from GitHub ===
curl -L -o mods.toml https://raw.githubusercontent.com/youruser/minecraft-pack/main/mods.toml
curl -L -o ferium.toml https://raw.githubusercontent.com/youruser/minecraft-pack/main/ferium.toml

REM === Install/update mods using Ferium ===
"%FERIUM_BIN%" profile use default || "%FERIUM_BIN%" profile create default
"%FERIUM_BIN%" install --output-dir "%MODS_DIR%"
