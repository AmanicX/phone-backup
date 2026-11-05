@echo off
setlocal enabledelayedexpansion

title OnePlus 7T - Instant SIM and IMEI Restore (Windows)
echo ==========================================================
echo     OnePlus 7T: Instant SIM and Repaired IMEI Restoration  
echo                   (Windows Version)                        
echo ==========================================================
echo.

set "BACKUP_DIR=%~dp0partitions"

if not exist "%BACKUP_DIR%" (
    echo [ERROR] Partitions directory not found: "%BACKUP_DIR%"
    echo Please make sure the partitions folder is located next to this script.
    echo If you cloned this repo, run unpack-backup.bat first!
    pause
    exit /b 1
)

echo [1/3] Checking connection...
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] 'adb' was not found in your system PATH.
    echo Please install Android Platform Tools on Windows or place adb.exe here.
    pause
    exit /b 1
)

adb devices | findstr /i "recovery" >nul
if %errorlevel% equ 0 (
    set "MODE=RECOVERY"
    echo Phone detected in OrangeFox / Recovery mode via ADB.
    goto :START_RESTORE
)

where fastboot >nul 2>nul
if %errorlevel% equ 0 (
    fastboot devices | findstr /i "fastboot" >nul
    if %errorlevel% equ 0 (
        set "MODE=FASTBOOT"
        echo Phone detected in Fastboot mode.
        goto :START_RESTORE
    )
)

echo [ERROR] Phone not detected in Recovery or Fastboot mode!
echo Please boot into OrangeFox Recovery (or Bootloader) and connect USB.
pause
exit /b 1

:START_RESTORE
echo.
echo [2/3] Restoring IMEI and SIM calibration partitions from %BACKUP_DIR% ...

set "PARTS=modemst1 modemst2 fsg fsc oem_stanvbk oem_dycnvbk mdm_oem_stanvbk mdm_oem_dycnvbk mdm1m9kefs1 mdm1m9kefs2 mdm1m9kefs3 mdm1m9kefsc mdm1oemnvbktmp persist param carrier"

for %%p in (%PARTS%) do (
    if not exist "%BACKUP_DIR%\%%p.img" (
        echo [ERROR] Missing file: %BACKUP_DIR%\%%p.img
        pause
        exit /b 1
    )
    echo  -^> Restoring %%p ...
    if "%MODE%"=="RECOVERY" (
        adb push "%BACKUP_DIR%\%%p.img" /dev/part_tmp.img >nul 2>nul
        adb shell "dd if=/dev/part_tmp.img of=/dev/block/bootdevice/by-name/%%p bs=4096 2>/dev/null || dd if=/dev/part_tmp.img of=/dev/block/by-name/%%p bs=4096 2>/dev/null"
        adb shell "rm -f /dev/part_tmp.img" >nul 2>nul
    ) else (
        fastboot flash %%p "%BACKUP_DIR%\%%p.img"
    )
)

echo.
echo [3/3] Rebooting phone...
if "%MODE%"=="RECOVERY" (
    adb reboot
) else (
    fastboot reboot
)

echo ==========================================================
echo SUCCESS: Your repaired IMEI and SIM calibration are restored!
echo The phone is rebooting into Android.
echo ==========================================================
pause
