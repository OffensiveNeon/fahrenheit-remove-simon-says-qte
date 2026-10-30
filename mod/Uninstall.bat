@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1" -Action Uninstall || goto fail
echo.
echo Done. The game is back to normal.
pause
exit /b 0
:fail
echo.
echo Something went wrong - see the message above.
pause
exit /b 1
