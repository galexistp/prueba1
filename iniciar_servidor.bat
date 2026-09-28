@echo off
echo Iniciando servidor local para Supermercado Alem...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
