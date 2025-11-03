@echo off
echo ========================================
echo Cleanup #2: Course Management Removal
echo ========================================
echo.
echo This will delete:
echo - 1 courses popup file
echo - 1 courses folder (6 files)
echo - 1 course dialog file (if exists)
echo.
echo Total: 7-8 files
echo.
echo NOTE: Courses sidebar item will remain
echo       (navigates to placeholder screen)
echo.
pause

echo.
echo Deleting courses popup...
del "lib\screens\admin\widgets\courses_popup.dart" 2>nul
if exist "lib\screens\admin\widgets\courses_popup.dart" (
    echo [ERROR] Could not delete courses_popup.dart
) else (
    echo [OK] Deleted courses_popup.dart
)

echo.
echo Deleting courses folder...
rmdir /s /q "lib\screens\admin\courses" 2>nul
if exist "lib\screens\admin\courses" (
    echo [ERROR] Could not delete courses folder
) else (
    echo [OK] Deleted courses folder (6 files)
)

echo.
echo Deleting course dialog...
del "lib\screens\admin\dialogs\add_course_dialog.dart" 2>nul
if exist "lib\screens\admin\dialogs\add_course_dialog.dart" (
    echo [ERROR] Could not delete add_course_dialog.dart
) else (
    echo [OK] Deleted add_course_dialog.dart (or didn't exist)
)

echo.
echo ========================================
echo Cleanup #2 Complete!
echo ========================================
echo.
echo What was removed:
echo - Course management popup menu
echo - All course management screens
echo - Course creation/editing interfaces
echo.
echo What was kept:
echo - Courses sidebar item (shows placeholder)
echo - Course data references in other screens
echo.
echo Next steps:
echo 1. Hot restart your Flutter app
echo 2. Login as admin
echo 3. Click Courses sidebar item
echo 4. Should see placeholder screen
echo 5. Check for any errors
echo.
pause
