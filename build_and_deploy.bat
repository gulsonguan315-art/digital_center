@echo off
echo Starting Flutter build and deploy...

echo.
echo [1/4] Running flutter clean...
call flutter clean

echo.
echo [2/4] Running flutter pub get...
call flutter pub get

echo.
echo [3/4] Building Windows release...
call flutter build windows --release

echo.
echo [4/4] Copying to target server...
if exist "build\windows\x64\runner\Release\" (
    :: Use robocopy /MIR to perfectly mirror the directory, but exclude user_settings.json
    robocopy "build\windows\x64\runner\Release" "\\192.168.0.2\data\Gulson_Lab\digital_center" /MIR /XF user_settings.json
    echo.
    echo Deployment successful!
) else (
    echo.
    echo ERROR: Build directory 'build\windows\x64\runner\Release\' not found.
    echo Please check the build output for errors.
)

echo.
pause
