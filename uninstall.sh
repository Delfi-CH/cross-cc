#!/usr/bin/env bash


# general setup stuff
set -euo pipefail

source targets.sh

# get cli args
OPTIONS=$(getopt -o hlt:d: -l help,list,target:,directory: -- "$@")

if [[ $? -ne 0 ]]; then
    echo "Invalid arguments" >&2
    exit 1
fi

eval set -- "$OPTIONS"

# cli options
READ_TARGET=""
BASEDIR="$HOME/opt/cross-cc"

# parse opts
while true; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [-h] [-l] [-t TARGET] [-d DIRECTORY]"
            echo "-h, --help                    Print this message"
            echo "-l, --list                    List all targets"
            echo "-t, --target <Target>         Uninstall this cross compiler"
            echo "-d,--directory <Directory>    Set the directory where the sysroot and the cross compiler are installed (default $HOME/opt/cross-cc)"
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

source "$BASEDIR/scripts/vars_$READ_TARGET.sh"

echo "WARNING !"
echo "'$SYSROOT' and '$PREFIX' will be recursivly deleted!"
echo "This operation cannot be undone!"
read -p "Are you sure you want to continiue? [y/n] " OK
if [ "$OK" != "y" ]; then
    echo "Aborting..."
    exit 1
else
    if [ ! -e "$SYSROOT" ] && [ ! -e "$PREFIX" ]; then
        echo "Could not find either $SYSROOT nor $PREFIX!"
        echo "Aborting..."
        exit 1
    fi
    rm -rf $SYSROOT $PREFIX
fi
echo "Done!"