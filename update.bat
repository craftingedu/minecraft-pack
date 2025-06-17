@echo off
setlocal enabledelayedexpansion

REM === Paths ===
set "CONFIG_DIR=%USERPROFILE%\minecraft-updater"
set "MODS_DIR=%APPDATA%\.prismlauncher\instances\crafting\minecraft\mods"
set "FERIUM_BIN=%USERPROFILE%\.cargo\bin\ferium.exe"

REM === Create folders if needed ===
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
if not exist "%MODS_DIR%" mkdir "%MODS_DIR%"

cd /d "%CONFIG_DIR%"

REM === Download latest mod configuration from GitHub ===
curl -L -o config.json https://raw.githubusercontent.com/craftingedu/minecraft-pack/main/config.json

REM === Copy config to Ferium config directory ===
set "FERIUM_CONFIG_DIR=%USERPROFILE%\.config\ferium"
if not exist "%FERIUM_CONFIG_DIR%" mkdir "%FERIUM_CONFIG_DIR%"
copy /Y config.json "%FERIUM_CONFIG_DIR%\config.json"

REM === Install/update mods using Ferium ===
"%FERIUM_BIN%" profile use crafting
"%FERIUM_BIN%" install --output-dir "%MODS_DIR%"
