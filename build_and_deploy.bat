@echo off
echo Starting Flutter build and deploy...

set NAS_DIR=\\192.168.0.2\data\Gulson_Lab\digital_center
set LOCK_FILE=%NAS_DIR%\deploy_status.json

echo.
echo [Locking NAS Deployment] Setting updatable = false ...
if exist "%NAS_DIR%" (
    echo {"updatable": false, "status": "building"} > "%LOCK_FILE%"
)

echo.
echo [1/4] Running flutter clean...
call flutter clean

echo.
echo [2/4] Running flutter pub get...
call flutter pub get

echo.
echo [3/4] Building Windows release...
call flutter build windows --release

if errorlevel 1 goto BUILD_FAILED

echo.
echo [4/4] Copying to target server...
if not exist "build\windows\x64\runner\Release\" goto BUILD_FAILED

robocopy "build\windows\x64\runner\Release" "%NAS_DIR%" /MIR /XF user_settings.json deploy_status.json

echo.
echo [Unlocking NAS Deployment] Setting updatable = true ...
if exist "%NAS_DIR%" (
    echo {"updatable": true, "status": "ready"} > "%LOCK_FILE%"
)

echo.
echo Deployment successful!
goto END

:BUILD_FAILED
echo.
echo ERROR: Build failed or build directory missing!
echo Resetting deployment lock status...
if exist "%NAS_DIR%" (
    echo {"updatable": true, "status": "error"} > "%LOCK_FILE%"
)

:END
echo.
pause
