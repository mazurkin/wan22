#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o monitor
set -o noglob

# calculate the current directory
SCRIPT_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
declare -r SCRIPT_DIR

# calculate the package directory
PACKAGE_DIR=$(dirname -- "${SCRIPT_DIR}")
declare -r PACKAGE_DIR

# calculate the model dir
MODEL_DIR="${PACKAGE_DIR}/models"
declare -r MODEL_DIR

# python settings
export PYTHONPATH="${PACKAGE_DIR}/wan22"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# torch settings
export PYTORCH_ALLOC_CONF=expandable_segments:True

exec conda run --no-capture-output --live-stream --name wan22 --cwd "${PACKAGE_DIR}" \
    python3 wan22/generate.py \
        "$@"
