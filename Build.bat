@echo off
setlocal enabledelayedexpansion

rem Read information from info.toml
for /f "tokens=1,* delims==" %%a in ('type "info.toml" ^| find "="') do (
    if "%%a"=="name " set name=%%b
    if "%%a"=="version " set version=%%b
)

rem Remove spaces from the name and version
set "name=!name: =!"
set "version=!version: =!"

rem Create the zip file
@REM set "zip_name=%name%_%version%.op"
set "zip_name=%name%.op"

rem Whitelisted folders and files
set "whitelist="
set "whitelist=%whitelist% src\*"
set "whitelist=%whitelist% info.toml"
set "whitelist=%whitelist% LICENSE"
set "whitelist=%whitelist% Readme.md"

copy "info.toml" "temp.info.toml"

@REM rem Perform string substitution
call BatchSubstitude.bat "ER_DEBUG" "ER_RELEASE" "temp.info.toml" > "info.toml"

rem Create the zip file
del /q "%zip_name%" 2>nul
"%ProgramFiles%\7-Zip\7z" a -tzip "%zip_name%" %whitelist%

move /y "temp.info.toml" "info.toml"

endlocal