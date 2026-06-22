#!/usr/bin/env bash
set -e

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
