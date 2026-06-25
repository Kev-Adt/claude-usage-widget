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
for /f "delims=" %%D in ('dir /b /ad /o-n "%BASE%" 2^>nul') do (
  if not defined EXE if exist "%BASE%\%%D\claude.exe" set "EXE=%BASE%\%%D\claude.exe"
)
if not defined EXE ( echo ERROR: no encontre claude.exe & pause & exit /b 1 )

"%EXE%" auth login --claudeai

echo.
echo --------------------------------------------
echo Si ves tu correo o "Login successful", LISTO.
echo El widget se actualizara solo en menos de 1 min.
echo Puedes cerrar esta ventana.
echo --------------------------------------------
pause
