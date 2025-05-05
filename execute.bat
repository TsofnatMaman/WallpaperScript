@echo off
set "psScript=%APPDATA%\Microsoft\Windows\script1.ps1"

echo download...
powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/TsofnatMaman/WallpaperScript/main/script1.ps1 -OutFile '%psScript%'"

if exist "%psScript%" (
    echo success
    powershell -ExecutionPolicy Bypass -File "%psScript%"
) else (
    echo error
)
