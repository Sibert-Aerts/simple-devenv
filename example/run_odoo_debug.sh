#!/bin/bash
set -e

# Configuration
DATABASE="bzbfedafin"
ODOO_VERSION="17.0"
ODOO_PATH="/opt/odoos/${ODOO_VERSION}"
VENV_PATH="/home/vincent/odoo_projects/testjes/venv"
CONFIG_PATH="/home/vincent/odoo_projects/testjes/odoo.conf"
MODULE_TO_UPDATE="abs_report_builder"
DEBUG_PORT=5678

# Database connection
CONNECTIONSTRING="postgresql://odoo:odoo@localhost:5432/${DATABASE}"

# Activate virtual environment
if [ ! -f "${VENV_PATH}/bin/activate" ]; then
    echo "Error: Virtual environment not found at ${VENV_PATH}"
    exit 1
fi
source "${VENV_PATH}/bin/activate"

# Function to find valid addon directories
find_addon_paths() {
    local search_dirs=("$@")
    local addons_path=""
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local paths=$(find "$dir" -type f \( -name "__manifest__.py" -o -name "__openerp__.py" \) 2>/dev/null |
                           xargs -I {} dirname {} |
                           xargs -I {} dirname {} |
                           grep -v '/tools/posbox' |
                           sort -u |
                           tr '\n' ',' |
                           sed 's/,$//')
            if [ -n "$paths" ]; then
                addons_path="${addons_path}${paths},"
            fi
        fi
    done
    echo "${addons_path%,}"
}

# Define addon paths
ADDON_DIRS=(
    "${ODOO_PATH}/odoo/addons"
    "${ODOO_PATH}/enterprise"
    "${ODOO_PATH}/design-themes"
    "/home/vincent/odoo_projects/bzbfedafin/custom_addons"
)

ADDONS_PATH=$(find_addon_paths "${ADDON_DIRS[@]}")

if [ -z "$ADDONS_PATH" ]; then
    echo "Error: No valid addon paths found"
    exit 1
fi

# Check if Odoo binary exists
if [ ! -f "${ODOO_PATH}/odoo/odoo-bin" ]; then
    echo "Error: Odoo binary not found at ${ODOO_PATH}/odoo/odoo-bin"
    exit 1
fi

# Start Odoo with debugger
echo "Starting Odoo in debug mode..."
UPDATE_ARG=""
if [ -n "${MODULE_TO_UPDATE}" ] && [[ ! "$*" =~ "-u" ]]; then
    UPDATE_ARG="-u ${MODULE_TO_UPDATE}"
fi

"${ODOO_PATH}/odoo/odoo-bin" \
    -c "${CONFIG_PATH}" \
    ${UPDATE_ARG} \
    -d "${DATABASE}" \
    --dev=xml,qweb \
    --log-level=debug \
    -u bzb_base,abs_report_builder \
    "$@"

