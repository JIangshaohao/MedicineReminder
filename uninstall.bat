@echo off
:: ============================================
::  Medicine Reminder - Uninstall Auto-Start
::  Right-click -> Run as Administrator
:: ============================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Please run as Administrator!
    echo.
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -Uninstall
