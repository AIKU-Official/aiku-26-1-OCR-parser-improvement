@echo off
title PDF Structure Suite - Installing...
color 0A

echo ================================================
echo   PDF Structure Suite - Install Program
echo   (Do not close this window)
echo ================================================
echo.

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
    echo [ERROR] Miniconda is not installed.
    echo Please install from: https://docs.conda.io/en/latest/miniconda.html
    pause
    exit /b 1
)

echo Found conda: %CONDA_ROOT%
echo.

call "%CONDA_ROOT%\Scripts\activate.bat" "%CONDA_ROOT%"
if errorlevel 1 (
    color 0C
    echo [ERROR] Failed to initialize conda.
    pause
    exit /b 1
)

echo [1/4] Creating virtual environment (python 3.10)...
echo.
call conda create -n ocr_app python=3.10 -y
if errorlevel 1 goto :error
echo [1/4] Done!
echo.

echo [2/4] Installing PaddlePaddle... (500MB~1GB, please wait)
echo.
call conda activate ocr_app
pip install paddlepaddle-gpu==3.3.0 --extra-index-url https://www.paddlepaddle.org.cn/packages/stable/cu126/
if errorlevel 1 (
    echo GPU version failed. Installing CPU version...
    pip install paddlepaddle==3.0.0
    if errorlevel 1 goto :error
)
echo [2/4] Done!
echo.

echo [3/4] Installing PaddleOCR and related packages...
echo.
pip install "paddleocr>=3.3.0,<3.6.0" "paddlex[ocr]>=3.5.0,<3.6.0"
if errorlevel 1 goto :error
pip install pymupdf opencv-python numpy Pillow openpyxl PyQt5 pyyaml tqdm pdfplumber
if errorlevel 1 goto :error
echo [3/4] Done!
echo.

echo [4/4] Downloading OCR models... (about 1GB, takes 5~10 min)
echo.
python -c "from paddleocr import PPStructureV3; PPStructureV3(device='cpu', use_doc_orientation_classify=False, use_doc_unwarping=False, use_textline_orientation=False); print('Model download complete')"
echo [4/4] Done!
echo.

color 0B
echo ================================================
echo   Installation complete!
echo   Run 'run.bat' to start the app.
echo ================================================
echo.
pause
exit /b 0

:error
color 0C
echo.
echo [ERROR] Installation failed. Check the error above.
echo.
pause
exit /b 1
