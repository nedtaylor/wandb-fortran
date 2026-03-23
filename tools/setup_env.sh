#!/usr/bin/env bash
# tools/setup_env.sh — export Python flags so that fpm can compile and link
# wf_wandb_c.c (which embeds Python) without any wrapper script.
#
# SOURCE this file — do not execute it:
#   source tools/setup_env.sh
#   PYTHON=/path/to/python3 source tools/setup_env.sh
#
# After sourcing you can run fpm directly:
#   fpm build
#   fpm run --example athena_logging
#
# To make this permanent, add the source line to your ~/.zshrc or ~/.bashrc.
#
# Prerequisites for the chosen Python:
#   <python> -m pip install wandb && wandb login

# Use return (not exit) so the file is safe to source from interactive shells.
_wf_err() { echo "ERROR (setup_env.sh): $*" >&2; return 1 2>/dev/null || exit 1; }

# --------------------------------------------------------------------------- #
#  Resolve Python interpreter                                                  #
# --------------------------------------------------------------------------- #
_WF_PY="${PYTHON:-python3}"

if ! command -v "$_WF_PY" &>/dev/null; then
    _wf_err "Python interpreter '$_WF_PY' not found."
fi

_WF_PY_ABS=$(command -v "$_WF_PY")
_WF_PY_VER=$("$_WF_PY_ABS" -c \
    "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
_WF_PY_DIR=$(dirname "$_WF_PY_ABS")

# Prefer the versioned python-config (python3.12-config) alongside the interpreter.
_WF_PY_CFG="${_WF_PY_DIR}/python${_WF_PY_VER}-config"
[[ -x "$_WF_PY_CFG" ]] || _WF_PY_CFG="${_WF_PY_DIR}/python3-config"

if [[ ! -x "$_WF_PY_CFG" ]]; then
    _wf_err "Could not find python${_WF_PY_VER}-config or python3-config \
alongside '$_WF_PY_ABS'. Install Python development headers."
fi

# --------------------------------------------------------------------------- #
#  Derive flags                                                                #
# --------------------------------------------------------------------------- #
_WF_INCLUDES=$("$_WF_PY_CFG" --includes)
_WF_LDFLAGS=$("$_WF_PY_CFG" --ldflags --embed 2>/dev/null \
              || "$_WF_PY_CFG" --ldflags)

# python-config's -L often points only to config-X.Y-darwin/, not the directory
# that holds the actual libpython dylib.  Prepend the real LIBDIR and bake in
# an rpath so the binary finds the dylib without DYLD_LIBRARY_PATH at runtime.
_WF_LIBDIR=$("$_WF_PY_ABS" -c \
    "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")
if [[ -n "$_WF_LIBDIR" ]]; then
    _WF_LDFLAGS="-L${_WF_LIBDIR} -Wl,-rpath,${_WF_LIBDIR} ${_WF_LDFLAGS}"
    # Also keep DYLD_LIBRARY_PATH so existing cached binaries can find the dylib
    # without a forced relink.
    export DYLD_LIBRARY_PATH="${_WF_LIBDIR}${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
fi

# --------------------------------------------------------------------------- #
#  Export                                                                      #
# --------------------------------------------------------------------------- #
export FPM_CFLAGS="${FPM_CFLAGS:-} ${_WF_INCLUDES}"
export FPM_LDFLAGS="${FPM_LDFLAGS:-} ${_WF_LDFLAGS}"

# Filter out -framework flags which are not supported by flang
# This allows the code to compile with both clang and flang
export FPM_LDFLAGS=$(echo "$FPM_LDFLAGS" | sed 's/ -framework [^ ]*//g')

echo "setup_env.sh: configured fpm for Python ${_WF_PY_VER} (${_WF_PY_ABS})"
echo "  FPM_CFLAGS  = $FPM_CFLAGS"
echo "  FPM_LDFLAGS = $FPM_LDFLAGS"
echo ""
echo "You can now run:  fpm build"

# --------------------------------------------------------------------------- #
#  Tidy up — don't leak private variables into the caller's shell              #
# --------------------------------------------------------------------------- #
unset _WF_PY _WF_PY_ABS _WF_PY_VER _WF_PY_DIR
unset _WF_PY_CFG _WF_INCLUDES _WF_LDFLAGS _WF_LIBDIR
