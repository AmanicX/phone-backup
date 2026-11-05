@echo off
setlocal enabledelayedexpansion

title OnePlus 7T - Exhaustive Hardware and Firmware Backup (Windows)
echo ==========================================================
echo     OnePlus 7T: Complete Firmware and Calibration Export   
echo                   (Windows Version)                        
echo ==========================================================
echo.

set "BACKUP_DIR=%~dp0partitions"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] 'adb' was not found in your system PATH.
    echo Please install Android Platform Tools or add adb.exe to PATH.
    pause
    exit /b 1
)

echo [1/3] Checking recovery connection...
adb devices
echo.

set "PARTS=modemst1 modemst2 fsg fsc oem_stanvbk oem_dycnvbk mdm_oem_stanvbk mdm_oem_dycnvbk mdm1m9kefs1 mdm1m9kefs2 mdm1m9kefs3 mdm1m9kefsc mdm1oemnvbktmp persist param carrier config devinfo secdata limits op1 op2 opproduct_a opproduct_b xbl_a xbl_b xbl_config_a xbl_config_b abl_a abl_b tz_a tz_b hyp_a hyp_b aop_a aop_b keymaster_a keymaster_b cmnlib_a cmnlib_b cmnlib64_a cmnlib64_b devcfg_a devcfg_b qupfw_a qupfw_b storsec_a storsec_b uefisecapp_a uefisecapp_b uefivarstore imagefv_a imagefv_b modem_a modem_b dsp_a dsp_b bluetooth_a bluetooth_b cdt ddr mdmddr catecontentfv catefv cateloader spunvm msadp apdp dip ALIGN_TO_128K_1 ALIGN_TO_128K_2 boot_a boot_b dtbo_a dtbo_b vbmeta_a vbmeta_b vbmeta_system_a vbmeta_system_b recovery_a recovery_b splash LOGO_a LOGO_b"

echo [2/3] Pulling all hardware and calibration partitions to:
echo "%BACKUP_DIR%"
echo.

for %%p in (%PARTS%) do (
    if exist "%BACKUP_DIR%\%%p.img" (
        echo  -^> [Skipping existing] %%p.img
    ) else (
        echo  -^> Pulling %%p ...
        adb pull "/dev/block/bootdevice/by-name/%%p" "%BACKUP_DIR%\%%p.img" 2>nul || adb pull "/dev/block/by-name/%%p" "%BACKUP_DIR%\%%p.img"
    )
)

echo.
echo [3/3] Export complete!
echo All partition files are saved in:
echo "%BACKUP_DIR%"
echo.
pause
