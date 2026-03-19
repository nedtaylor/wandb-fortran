#!/usr/bin/env bash
# build_fpm.sh — build wandb-fortran with fpm.
#
# This script sets up the Python flags needed to compile and link wf_wandb_c.c,
# then runs fpm build.  To use fpm directly (without this script), source
# tools/setup_env.sh in your shell session first:
#
#   source tools/setup_env.sh
#   fpm build
#
# Usage:
#   ./build_fpm.sh                                       # use PATH python3
#   PYTHON=/path/to/python3 ./build_fpm.sh               # specific interpreter
#
#   # Example: use a conda environment's Python:
#   PYTHON=/opt/homebrew/Caskroom/miniconda/base/envs/my_env/bin/python \
#       ./build_fpm.sh
#
# Prerequisites for the chosen Python:
#   <python> -m pip install wandb && wandb login
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source setup_env.sh to export FPM_CFLAGS / FPM_LDFLAGS / DYLD_LIBRARY_PATH.
# PYTHON is forwarded from the environment if set.
source "${SCRIPT_DIR}/tools/setup_env.sh"

echo ""
echo "Building wandb-fortran..."
fpm build
