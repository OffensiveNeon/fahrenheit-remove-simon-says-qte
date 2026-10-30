@echo off
cd /d "%~dp0"
if not exist "FahrenheitSub.exe" (
  echo FahrenheitSub.exe not found. Put these files in the game folder first.
  echo Steam: right-click the game, Manage, Browse local files.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1" -Action Install || goto fail
echo.
echo Done. QTEs will now pass on their own.
pause
exit /b 0
:fail
echo.
echo Something went wrong - see the message above.
pause
exit /b 1
