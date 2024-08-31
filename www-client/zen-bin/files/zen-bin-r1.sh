#!/bin/bash

##
## Usage:
##
## $ zen-bin [args]
##
## This script is meant to run Zen Browser.
##
## Based on the firefox-bin-r1.sh shell script.
##

MOZ_ARCH=$(uname -m)
case ${MOZ_ARCH} in
	x86_64|amd64)
		MOZ_LIB_DIR="@PREFIX@/lib64"
		;;
	*)
		MOZ_LIB_DIR="@PREFIX@/lib"
		;;
esac

MOZ_FIREFOX="@MOZ_FIVE_HOME@/zen-bin"
MOZ_APULSE_LIB_DIR="@APULSELIB_DIR@"

# Allow users to override command-line options
if [[ -f ~/.zen-bin-command-line ]]; then
	USER_PARAMS="$(cat ~/.zen-bin-command-line)"
fi

# Use settings from /etc/env.d/zen-bin if possible
if [[ -f /etc/env.d/zen-bin ]]; then
	. /etc/env.d/zen-bin
fi

# Use Wayland if enabled
if [[ "@DEFAULT_WAYLAND@" == "true" ]] && [[ -z "${MOZ_DISABLE_WAYLAND}" ]]; then
	export MOZ_ENABLE_WAYLAND=1
fi

# Use apulse if available
if [[ -n ${MOZ_APULSE_LIB_DIR} ]]; then
	export LD_LIBRARY_PATH="${MOZ_APULSE_LIB_DIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

# Disable Alsa for PulseAudio users
if [[ -e "${MOZ_LIB_DIR}/apulse/libpulse.so" ]] && [[ -e "${MOZ_LIB_DIR}/apulse/libpulse-simple.so" ]]; then
	export LD_LIBRARY_PATH="${MOZ_LIB_DIR}/apulse${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

# Run Zen Browser
exec "${MOZ_FIREFOX}" ${USER_PARAMS} "$@"
