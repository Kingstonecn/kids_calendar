@echo off
echo TEST: PATH contains git?
echo %PATH% | findstr /i git >nul && echo YES || echo NO
echo.
echo Trying to find git...
where git 2>nul && echo GIT FOUND || echo GIT NOT FOUND
echo.
echo Setting PATH...
set PATH=C:\Program Files\Git\bin;%PATH%
echo.
where git 2>nul && echo GIT NOW FOUND || echo GIT STILL NOT FOUND
