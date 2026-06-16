#!/usr/bin/env bash
set -e

BUILD_DIR="build"

# osx-64 compatibility (https://conda-forge.org/docs/maintainer/knowledge_base/#newer-c-features-with-old-sdk)
export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

# Ensure cstdlib is included to fix 'free' visibility issues with fmt library
export CXXFLAGS="${CXXFLAGS} -include cstdlib"

rm -rf "${SRC_DIR}/contrib/"

cmake ${CMAKE_ARGS} -S ${SRC_DIR} \
 -B ${BUILD_DIR} \
 -G "Ninja" \
 -D CMAKE_BUILD_TYPE=Release \
 -D EXTERNAL_LIBOSMIUM=ON \
 -D EXTERNAL_FMT=ON \
 -D EXTERNAL_CLI11=ON \
 -D EXTERNAL_PROTOZERO=ON \
 -D CMAKE_INSTALL_PREFIX="${PREFIX}" \
 -D CMAKE_FIND_FRAMEWORK=NEVER \
 -D CMAKE_FIND_APPBUNDLE=NEVER \
 -D CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF \
 -D CMAKE_PREFIX_PATH="${PREFIX};${BUILD_PREFIX}" \
 -D Boost_INCLUDE_DIR="${BUILD_PREFIX}/include" \
 -D NLOHMANN_INCLUDE_DIR="${BUILD_PREFIX}/include" \
 -D LUA_INCLUDE_DIR="${PREFIX}/include" \
 -D LUA_LIBRARY="${PREFIX}/lib/liblua${SHLIB_EXT}"

cmake --build ${BUILD_DIR} --target all --parallel ${CPU_COUNT}

cmake --install ${BUILD_DIR}

# Replace the raw script installed by CMake with a proper Python entry point.
# The CMake-installed script has a #!/usr/bin/env python3 shebang that resolves
# the interpreter from the calling shell's PATH at runtime, which breaks when
# another conda/Python environment is active. A pip-generated entry point uses
# sys.executable (the prefix-absolute interpreter path) and is correctly
# relocated by conda when the package is installed.

# Remove the raw script; we will replace it via pip.
rm "${PREFIX}/bin/osm2pgsql-replication"

# Stage a minimal pip-installable package that wraps the script as a module.
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGING_DIR}"' EXIT

# The script is a self-contained module; copy it under a package name that
# won't collide with anything on PyPI or in the conda environment.
mkdir "${STAGING_DIR}/osm2pgsql_replication"
cp "${SRC_DIR}/scripts/osm2pgsql-replication" \
   "${STAGING_DIR}/osm2pgsql_replication/__init__.py"

cp "${RECIPE_DIR}/pyproject.toml" "${STAGING_DIR}/pyproject.toml"

${PYTHON} -m pip install "${STAGING_DIR}" \
    --no-deps --no-build-isolation -vv
