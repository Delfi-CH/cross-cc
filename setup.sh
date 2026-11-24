#!/usr/bin/env bash

# general setup stuff
set -euo pipefail

READ_TARGET=""
TARGET_LIST=("x86_64-pc-freebsd15.1" "aarch64-unknown-freebsd15.1")
export BASEDIR="$HOME/opt/cross-cc"

if [ "$#" -gt 0 ]; then
    if [ "$1" == "--list-targets" ] || [ "$1" == "-l" ]; then
        for i in "${TARGET_LIST[@]}"; do
            echo "$i"
        done
        exit 1
    fi
    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        echo "Usage: $0 <(optional) target name>"
        echo "-h --help         Print this message"
        echo "-l --list-targets List all targets"
        exit 1
    fi

    READ_TARGET="$1"
else 

    echo "Supported Targets:"
    for i in "${TARGET_LIST[@]}"; do
        echo "$i"
    done
    read -r -p "Select a target: " READ_TARGET
fi

FAIL=0

for i in "${TARGET_LIST[@]}"; do
    if [ "$i" == "$READ_TARGET" ]; then
        FAIL=1
    fi
done

if [ "$FAIL" -eq 0 ]; then
    echo "$READ_TARGET is not a valid target!"
    exit 1
fi

"$BASEDIR/scripts/build_$READ_TARGET.sh"