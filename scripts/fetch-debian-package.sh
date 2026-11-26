#!/usr/bin/env bash
set -euo pipefail

ARCHITECTURES=("amd64" "arm64" "i386")
RELEASES=("trixie" "bookworm")
BASE=https://deb.debian.org/debian

OPTIONS=$(getopt -o hlp:a:r: -l help,list,package:architecture:release: -- "$@")

if [[ $? -ne 0 ]]; then
    echo "Invalid arguments" >&2
    exit 1
fi

eval set -- "$OPTIONS"

SELECTED_PACKAGE=""
SELECTED_ARCH="amd64"
SELECTED_RELEASE="trixie"

while true; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [-h] [-l] [-p PACKAGE] [-a ARCHITECTURE] [-r RELEASE]"
            echo "-h,--help                         Print this message"
            echo "-l,--list                         List all architectures and releases"
            echo "-p,--package <Package>            Download this package"
            echo "-a,--architecture <Architecture>  Download package for this architecture (default ${ARCHITECTURES[0]})"
            echo "-r,--release <Release Name>       Download package from this debian release (default ${RELEASES[0]})"
            exit 0
            ;;
        -l|--list)
            echo "Supported Architectures: ${ARCHITECTURES[@]}"
            echo "Supported Releases: ${RELEASES[@]}"
            exit 0
            ;;
        -p|--package)
            SELECTED_PACKAGE="$2"
            shift 2
            ;;
        -a|--architecture)
            SELECTED_ARCH="$2"
            shift 2
            ;;
        -r|--release)
            SELECTED_RELEASE="$2"
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

if [ "$SELECTED_PACKAGE" == "" ]; then
    echo "You have to select a package with -p/--package!"
    exit 1
fi

FAIL=0

for i in "${ARCHITECTURES[@]}"; do
    if [ "$i" == "$SELECTED_ARCH" ]; then
        FAIL=1
    fi
done

if [ "$FAIL" -eq 0 ]; then
    echo "$SELECTED_ARCH is not a valid architecture!"
    exit 1
fi

FAIL=0

for i in "${RELEASES[@]}"; do
    if [ "$i" == "$SELECTED_RELEASE" ]; then
        FAIL=1
    fi
done

if [ "$FAIL" -eq 0 ]; then
    echo "$SELECTED_RELEASE is not a valid release!"
    exit 1
fi

mkdir -p /tmp/cross-cc/debian-downloads
cd /tmp/cross-cc/debian-downloads

wget -q -c "$BASE/dists/$SELECTED_RELEASE/main/binary-$SELECTED_ARCH/Packages.xz" -O Packages.xz
xz -df Packages.xz

PATH_IN_REPO=$(
    awk -v pkg="$SELECTED_PACKAGE" '
        BEGIN { RS=""; FS="\n" }
        {
            name=""
            filename=""
            for (i=1; i<=NF; i++) {
                if ($i ~ /^Package: /)
                    name=substr($i,10)
                if ($i ~ /^Filename: /)
                    filename=substr($i,11)
            }
            if (name == pkg)
                print filename
        }
    ' Packages | tail -n 1
)

if [ -z "$PATH_IN_REPO" ]; then
    echo "Package not found: $SELECTED_PACKAGE"
    exit 1
fi

wget -c "$BASE/$PATH_IN_REPO" -O "$SELECTED_PACKAGE-$SELECTED_ARCH-$SELECTED_RELEASE.deb"

echo "Downloaded to /tmp/cross-cc/debian-downloads/$SELECTED_PACKAGE-$SELECTED_ARCH-$SELECTED_RELEASE.deb"