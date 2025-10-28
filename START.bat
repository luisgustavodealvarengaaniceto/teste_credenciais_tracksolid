@echo off
REM Script para iniciar o Tracksolid API Debugger no Windows

echo.
echo ==========================================
echo  Tracksolid API Debugger
echo  Iniciando servidor...
echo ==========================================
echo.

node server.js

REM Se o servidor encerrar, manter a janela aberta
echo.
echo Servidor encerrado.
pause
