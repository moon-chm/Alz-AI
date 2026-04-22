@echo off
echo 🔍 Running Pre-Push Secret Audit...
echo ===================================

git diff --cached | findstr /R /I "password secret token key api_url"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ⚠️  WARNING: Potential secrets or URLs detected in staged changes!
    echo Please review your changes before committing.
) else (
    echo.
    echo ✅ No obvious secrets found in staged changes.
)

echo ===================================
