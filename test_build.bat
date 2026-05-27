@echo off
echo Step 1: PATH check
where git >nul 2>&1
if %ERRORLEVEL% EQU 0 (echo GIT FOUND IN PATH) else (echo GIT NOT IN PATH)

echo Step 2: Adding mingit to PATH
set PATH=D:\flutter\bin\mingit\cmd;%PATH%

echo Step 3: Re-check
where git >nul 2>&1
if %ERRORLEVEL% EQU 0 (echo GIT NOW FOUND) else (echo GIT STILL NOT FOUND)

echo Step 4: Running flutter
call D:\flutter\bin\flutter.bat build apk --debug
echo EXIT CODE: %ERRORLEVEL%
