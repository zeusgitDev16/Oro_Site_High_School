@echo off
echo ========================================
echo Oro Site High School - Cleanup Script
echo ========================================
echo.
echo This will delete:
echo - 2 popup files
echo - 1 attendance folder (5 files)
echo - 1 attendance report file
echo.
echo Total: 8 files
echo.
pause

echo.
echo Deleting popup files...
del "lib\screens\admin\widgets\sections_popup.dart" 2>nul
if exist "lib\screens\admin\widgets\sections_popup.dart" (
    echo [ERROR] Could not delete sections_popup.dart
) else (
    echo [OK] Deleted sections_popup.dart
)

del "lib\screens\admin\widgets\attendance_popup.dart" 2>nul
if exist "lib\screens\admin\widgets\attendance_popup.dart" (
    echo [ERROR] Could not delete attendance_popup.dart
) else (
    echo [OK] Deleted attendance_popup.dart
)

echo.
echo Deleting attendance folder...
rmdir /s /q "lib\screens\admin\attendance" 2>nul
if exist "lib\screens\admin\attendance" (
    echo [ERROR] Could not delete attendance folder
) else (
    echo [OK] Deleted attendance folder (5 files)
)

echo.
echo Deleting attendance reports...
del "lib\screens\admin\reports\attendance_reports_screen.dart" 2>nul
if exist "lib\screens\admin\reports\attendance_reports_screen.dart" (
    echo [ERROR] Could not delete attendance_reports_screen.dart
) else (
    echo [OK] Deleted attendance_reports_screen.dart
)

echo.
echo ========================================
echo Cleanup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Hot restart your Flutter app
echo 2. Login as admin
echo 3. Verify sidebar shows only 5 items
echo 4. Check for any errors
echo.
pause
