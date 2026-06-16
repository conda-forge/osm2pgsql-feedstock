setlocal EnableDelayedExpansion

set "BUILD_DIR=build"

if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"

if exist "%SRC_DIR%\osm2pgsql\contrib" rmdir /s /q "%SRC_DIR%\osm2pgsql\contrib"

cmake %CMAKE_ARGS% -S "%SRC_DIR%" ^
  -B "%BUILD_DIR%" ^
  -G "Ninja" ^
  -D CMAKE_BUILD_TYPE=Release ^
  -D EXTERNAL_LIBOSMIUM=ON ^
  -D EXTERNAL_FMT=ON ^
  -D EXTERNAL_CLI11=ON ^
  -D EXTERNAL_PROTOZERO=ON ^
  -D CMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%"

if errorlevel 1 exit /b 1

cmake --build "%BUILD_DIR%" --target all --parallel %CPU_COUNT%

if errorlevel 1 exit /b 1

cmake --install "%BUILD_DIR%"

if errorlevel 1 exit /b 1

:: Replace the raw script installed by CMake with a proper Python entry point.
:: See build.sh for the full rationale.

del "%LIBRARY_PREFIX%\bin\osm2pgsql-replication"

set "STAGING_DIR=%TEMP%\osm2pgsql-replication-staging"
if exist "%STAGING_DIR%" rmdir /s /q "%STAGING_DIR%"
mkdir "%STAGING_DIR%\osm2pgsql_replication"

copy "%SRC_DIR%\scripts\osm2pgsql-replication" ^
     "%STAGING_DIR%\osm2pgsql_replication\__init__.py"

if errorlevel 1 exit /b 1

(
echo [build-system]
echo requires = ["setuptools"]
echo build-backend = "setuptools.backends.legacy:build"
echo.
echo [project]
echo name = "osm2pgsql-replication"
echo version = "0.0.1"
echo requires-python = ">=3.6"
echo.
echo [project.scripts]
echo osm2pgsql-replication = "osm2pgsql_replication:main"
) > "%STAGING_DIR%\pyproject.toml"

%PYTHON% -m pip install "%STAGING_DIR%" --no-deps --no-build-isolation -vv

if errorlevel 1 exit /b 1

rmdir /s /q "%STAGING_DIR%"
