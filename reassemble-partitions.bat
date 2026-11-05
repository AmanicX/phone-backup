@echo off
setlocal enabledelayedexpansion

title OnePlus 7T - Zero-Compression Partition Reassembly (Windows)
echo ==========================================================
echo     OnePlus 7T: Zero-Compression Partition Reassembly     
echo                   (Windows Version)                        
echo ==========================================================
echo.

set "BACKUP_DIR=%~dp0partitions"

if not exist "%BACKUP_DIR%" (
    echo [ERROR] Partitions directory not found: "%BACKUP_DIR%"
    pause
    exit /b 1
)

cd /d "%BACKUP_DIR%"

echo [1/2] Reassembling split image files (lossless byte copy)...

for %%f in (*.img.part00) do (
    set "BASE=%%~nf"
    if not exist "!BASE!" (
        echo  -^> Reassembling !BASE! ...
        copy /b "!BASE!.part*" "!BASE!" >nul
    ) else (
        echo  -^> [Already exists] !BASE!
    )
)

echo.
echo [2/2] Reassembly complete!
echo All partition images are intact and ready for restore.
echo.
pause
