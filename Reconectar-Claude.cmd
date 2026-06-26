@echo off
title Reconectar Claude
echo ============================================
echo   Reconectar Claude (token vencido)
echo ============================================
echo.
echo Se abrira tu navegador. Inicia sesion y autoriza.
echo Si el navegador muestra un CODIGO, copialo y pegalo
echo aqui abajo cuando diga "Paste code here".
echo.

set "BASE=%APPDATA%\Claude\claude-code"
set "EXE="
rem 1) carpeta de version mas nueva
for /f "delims=" %%D in ('dir /b /ad /o-n "%BASE%" 2^>nul') do (
  if not defined EXE if exist "%BASE%\%%D\claude.exe" set "EXE=%BASE%\%%D\claude.exe"
)
rem 2) respaldo: busqueda recursiva (por si cambia la estructura tras una actualizacion)
if not defined EXE for /f "delims=" %%F in ('dir /s /b "%BASE%\claude.exe" 2^>nul') do (
  if not defined EXE set "EXE=%%F"
)
rem 3) ultimo respaldo: el comando 'claude' del PATH
if not defined EXE for %%G in (claude.exe claude.cmd) do (
  if not defined EXE if not "%%~$PATH:G"=="" set "EXE=%%~$PATH:G"
)
if not defined EXE ( echo ERROR: no encontre claude.exe - abre Claude Code una vez y reintenta & pause & exit /b 1 )

"%EXE%" auth login --claudeai

echo.
echo --------------------------------------------
echo Si ves tu correo o "Login successful", LISTO.
echo El widget se actualizara solo en menos de 1 min.
echo Puedes cerrar esta ventana.
echo --------------------------------------------
pause
