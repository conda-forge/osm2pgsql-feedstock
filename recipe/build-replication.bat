@echo off
setlocal EnableDelayedExpansion

set "STAGING_DIR=%TEMP%\osm2pgsql_replication_stage_%RANDOM%"
mkdir "%STAGING_DIR%"
if errorlevel 1 exit /b 1

mkdir "%STAGING_DIR%\osm2pgsql_replication"
if errorlevel 1 exit /b 1

copy "%SRC_DIR%\scripts\osm2pgsql-replication" ^
     "%STAGING_DIR%\osm2pgsql_replication\__init__.py"
if errorlevel 1 exit /b 1

copy "%RECIPE_DIR%\pyproject.toml" "%STAGING_DIR%\pyproject.toml"
if errorlevel 1 exit /b 1

"%PYTHON%" -m pip install "%STAGING_DIR%" ^
    --no-deps --no-build-isolation -vv
if errorlevel 1 exit /b 1

rmdir /s /q "%STAGING_DIR%"
