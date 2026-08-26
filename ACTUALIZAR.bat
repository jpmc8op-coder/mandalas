@echo off
REM Doble clic aqui para publicar la web o compilar el APK.
REM No hay que abrir ninguna terminal ni escribir comandos.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "dev\actualizar.ps1"
echo.
pause
