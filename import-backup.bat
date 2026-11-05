@echo off
setlocal enabledelayedexpansion

title OnePlus 7T - Complete Partition Restore and Rollback (Windows)
echo ==========================================================
echo     OnePlus 7T: Complete Partition Restore and Rollback   
echo                   (Windows Version)                        
echo ==========================================================
echo.

set "BACKUP_DIR=%~dp0partitions"

if not exist "%BACKUP_DIR%" (
    echo [ERROR] Partitions directory not found: "%BACKUP_DIR%"
    echo Please make sure the partitions folder is located next to this script.
    pause
    exit /b 1
)

echo Select what you want to restore:
echo   [1] SIM, IMEI ^& Baseband Calibration ONLY (modemst1/2, fsg, fsc, persist, nvram)
echo   [2] Boot, Kernel ^& Verified Boot ONLY (boot, dtbo, vbmeta)
echo   [3] Complete Full Rollback (All firmware, bootloaders, and calibration)
echo   [4] Cancel / Exit
echo.
set /p CHOICE="Enter choice [1-4]: "

if "%CHOICE%"=="1" (
    set "PARTS=modemst1 modemst2 fsg fsc oem_stanvbk oem_dycnvbk mdm_oem_stanvbk mdm_oem_dycnvbk mdm1m9kefs1 mdm1m9kefs2 mdm1m9kefs3 mdm1m9kefsc mdm1oemnvbktmp persist param carrier"
    goto :CHECK_CONNECTION
)
if "%CHOICE%"=="2" (
    set "PARTS=boot_a boot_b dtbo_a dtbo_b vbmeta_a vbmeta_b vbmeta_system_a vbmeta_system_b recovery_a recovery_b"
    goto :CHECK_CONNECTION
)
if "%CHOICE%"=="3" (
    set "PARTS=modemst1 modemst2 fsg fsc oem_stanvbk oem_dycnvbk mdm_oem_stanvbk mdm_oem_dycnvbk mdm1m9kefs1 mdm1m9kefs2 mdm1m9kefs3 mdm1m9kefsc mdm1oemnvbktmp persist param carrier config devinfo secdata limits xbl_a xbl_b xbl_config_a xbl_config_b abl_a abl_b tz_a tz_b hyp_a hyp_b aop_a aop_b keymaster_a keymaster_b cmnlib_a cmnlib_b cmnlib64_a cmnlib64_b devcfg_a devcfg_b qupfw_a qupfw_b storsec_a storsec_b uefisecapp_a uefisecapp_b uefivarstore imagefv_a imagefv_b modem_a modem_b dsp_a dsp_b bluetooth_a bluetooth_b cdt ddr mdmddr catecontentfv catefv cateloader spunvm msadp apdp dip ALIGN_TO_128K_1 ALIGN_TO_128K_2 boot_a boot_b dtbo_a dtbo_b vbmeta_a vbmeta_b vbmeta_system_a vbmeta_system_b recovery_a recovery_b splash LOGO_a LOGO_b op1 op2 opproduct_a opproduct_b"
    goto :CHECK_CONNECTION
)
if "%CHOICE%"=="4" (
    echo Operation cancelled by user.
    pause
    exit /b 0
)

echo Invalid choice.
pause
exit /b 1

:CHECK_CONNECTION
echo.
echo ==========================================================
echo ATTENTION: You are about to flash partitions to your phone!
echo Selected list: %PARTS%
echo ==========================================================
echo Type RESTORE to confirm:
set /p CONFIRM="> "

if not "%CONFIRM%"=="RESTORE" (
    echo Confirmation mismatch. Aborted.
    pause
    exit /b 1
)

echo.
echo [1/3] Detecting phone connection...
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
    goto :DO_RESTORE
)

where fastboot >nul 2>nul
if %errorlevel% equ 0 (
    fastboot devices | findstr /i "fastboot" >nul
    if %errorlevel% equ 0 (
        set "MODE=FASTBOOT"
        echo Phone detected in Fastboot mode.
        goto :DO_RESTORE
    )
)

echo [ERROR] Phone not detected in Recovery (adb) or Fastboot mode!
echo Please connect phone in OrangeFox Recovery or Bootloader.
pause
exit /b 1

:DO_RESTORE
echo.
echo [2/3] Writing partitions...

for %%p in (%PARTS%) do (
    if not exist "%BACKUP_DIR%\%%p.img" (
        echo [ERROR] File not found: "%BACKUP_DIR%\%%p.img"
        echo If this is a split partition, run reassemble-partitions.bat first!
        pause
        exit /b 1
    )
    echo  -^> Restoring %%p from %%p.img ...
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
echo SUCCESS: Partition restoration completed successfully!
echo ==========================================================
pause
