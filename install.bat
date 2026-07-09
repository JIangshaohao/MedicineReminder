@echo off
:: ============================================
::  Medicine Reminder - Install Auto-Start
::  Right-click -> Run as Administrator
:: ============================================

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Please run as Administrator!
    echo [Right-click this file - Run as administrator]
    echo.
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
