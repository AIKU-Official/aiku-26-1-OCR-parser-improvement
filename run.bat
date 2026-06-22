@echo off
title PDF Structure Suite

REM Find conda root directory
set CONDA_ROOT=
if exist "%USERPROFILE%\miniconda3\Scripts\conda.exe" set CONDA_ROOT=%USERPROFILE%\miniconda3
if exist "%USERPROFILE%\anaconda3\Scripts\conda.exe" set CONDA_ROOT=%USERPROFILE%\anaconda3
if exist "C:\miniconda3\Scripts\conda.exe" set CONDA_ROOT=C:\miniconda3
if exist "C:\anaconda3\Scripts\conda.exe" set CONDA_ROOT=C:\anaconda3
if exist "C:\ProgramData\miniconda3\Scripts\conda.exe" set CONDA_ROOT=C:\ProgramData\miniconda3
if exist "C:\ProgramData\anaconda3\Scripts\conda.exe" set CONDA_ROOT=C:\ProgramData\anaconda3

if "%CONDA_ROOT%"=="" (
    color 0C
    echo [ERROR] Miniconda not found. Please run install.bat first.
    pause
    exit /b 1
)

call "%CONDA_ROOT%\Scripts\activate.bat" "%CONDA_ROOT%"
call conda activate ocr_app 2>nul
if errorlevel 1 (
    color 0C
    echo [ERROR] ocr_app environment not found. Please run install.bat first.
    pause
    exit /b 1
)

cd /d "%~dp0"
python main.py

if errorlevel 1 (
    echo.
    echo [ERROR] App crashed.
    pause
)
