#!/usr/bin/env bash

# general setup stuff
set -euo pipefail

# constants
TARGET_LIST=("x86_64-pc-freebsd15.1" "aarch64-unknown-freebsd15.1")

# get cli args
OPTIONS=$(getopt -o hlt:d:j:sv -l help,list,target:,directory:,jobs:,silent,verbose -- "$@")

if [[ $? -ne 0 ]]; then
    echo "Invalid arguments" >&2
    exit 1
fi

eval set -- "$OPTIONS"

# cli options
READ_TARGET=""
BASEDIR="$HOME/opt/cross-cc"
JOBS=$(nproc)
OUTPUT_MODE="verbose"

# parse opts
while true; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [-h] [-l] [-t TARGET] [-d DIRECTORY] [-j JOBS] [-s] [-v]"
            echo "-h, --help                    Print this message"
            echo "-l, --list                    List all targets"
            echo "-t, --target <Target>         Build and install a cross compiler"
            echo "-d,--directory <Directory>    Set the directory where the sysroot and the cross compiler will be installed (default $HOME/opt/cross-cc)"
            echo "-j,--jobs <Count>             Set the amount of processes make is allowed to spawn (default $(nproc))"
            echo "-s,--silent                   Dont output anything (default off)"
            echo "-v,--verbose                  Output as much information as possible (default on)"
            exit 0
            ;;
        -l|--list)
            for i in "${TARGET_LIST[@]}"; do
                echo "$i"
            done
            exit 0
            ;;
        -t|--target)
            READ_TARGET="$2"
            shift 2
            ;;
        -d|--directory)
            BASEDIR="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -s|--silent)
            OUTPUT_MODE="silent"
            shift 1
            ;;
        -v|--verbose)
            OUTPUT_MODE="verbose"
            shift 1
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Illegal option: $1" >&2
            exit 1
            ;;
    esac
done

if [ "$READ_TARGET" == "" ]; then
    echo "You have to set a target with -t/--target!"
    exit 1
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

export BASEDIR
export JOBS

if [ "$OUTPUT_MODE" == "silent" ]; then
    "$BASEDIR/scripts/build_$READ_TARGET.sh" > /dev/null 2>&1
else 
    "$BASEDIR/scripts/build_$READ_TARGET.sh"
fi
