@echo off
setlocal
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"

if /i "%~1"=="update" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\setup.ps1" -Update
    exit /b
)
if not exist "%ROOT%\app\npm\9router.cmd" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\setup.ps1"
    if errorlevel 1 ( echo Setup failed. & pause & exit /b 1 )
)

set "PATH=%ROOT%\runtime\node;%ROOT%\app\npm;%PATH%"
set "USERPROFILE=%ROOT%\home"
set "HOME=%ROOT%\home"
set "APPDATA=%ROOT%\home\AppData\Roaming"
set "LOCALAPPDATA=%ROOT%\home\AppData\Local"
set "TEMP=%ROOT%\temp"
set "TMP=%ROOT%\temp"
set "npm_config_prefix=%ROOT%\app\npm"
set "npm_config_cache=%ROOT%\cache\npm"
set "npm_config_update_notifier=false"
set "DATA_DIR=%ROOT%\data"
set "INITIAL_PASSWORD=123456"
if exist "%ROOT%\data\initial-password.txt" set /p INITIAL_PASSWORD=<"%ROOT%\data\initial-password.txt"

node "%ROOT%\scripts\sqlite-guard.js"

echo 9Router: http://localhost:20128   (password: %INITIAL_PASSWORD%)
call "%ROOT%\app\npm\9router.cmd" --no-browser --host 127.0.0.1
pause
