#!/usr/bin/env bash

# general setup stuff
set -euo pipefail

source vars_aarch64-unknown-freebsd15.1.sh

mkdir -p "$PREFIX"
mkdir -p "$SYSROOT"

# aquire a freebsd sysroot
if [ -e "$SYSROOT/usr" ]; then
    echo "Sysroot already exists!"
else

wget https://download.freebsd.org/releases/arm64/15.1-RELEASE/base.txz
tar -xJf base.txz -C "$SYSROOT"
rm base.txz

wget https://download.freebsd.org/releases/arm64/15.1-RELEASE/lib32.txz
tar -xJf lib32.txz -C "$SYSROOT"
rm lib32.txz

fi

# compiler prefix setup stuff

cd "$PREFIX"

BUILD=$(gcc -dumpmachine)
HOST=$BUILD

mkdir -p "$PREFIX/bin" "$PREFIX/lib"


# building binutils
if [ -e "$PREFIX/bin/$TARGET-ar" ]; then
    echo "Binutils already exist!"
else

wget https://ftp.gnu.org/gnu/binutils/binutils-2.47.tar.gz
tar zxvf binutils-2.47.tar.gz
mkdir -p binutils-2.47/build
cd binutils-2.47/build
../configure \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --host="$HOST" \
    --with-sysroot="$SYSROOT" \
    --disable-nls \
    --disable-werror
make -j$(nproc)
make check
make install
cd $PREFIX
rm -rf binutils-2.47*

fi

# building gmp
if [ -e "$PREFIX/lib/libgmp.so" ]; then
    echo "GMP already exists!"
else

wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.gz
tar zxvf gmp-6.3.0.tar.gz
mkdir -p gmp-6.3.0/build
cd gmp-6.3.0/build
sed -i '/long long t1;/,+1s/()/(...)/' ../configure
../configure --prefix=$PREFIX --enable-shared --enable-static --enable-fft --disable-cxx --host=$HOST
make -j$(nproc)
make check
make install
cd $PREFIX
rm -rf gmp-6.3.0*

fi

# building mpfr
if [ -e "$PREFIX/lib/libmpfr.so" ]; then
    echo "MPFR already exists!"
else

wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.gz
tar zxvf mpfr-4.2.2.tar.gz
mkdir -p mpfr-4.2.2/build
cd mpfr-4.2.2/build
../configure --prefix=$PREFIX  --with-gnu-ld --with-gmp=$PREFIX --enable-static --enable-shared --host=$HOST
make -j$(nproc)
make check
make install
cd $PREFIX
rm -rf mpfr-4.2.2*

fi

# building mpc

# building mpfr
if [ -e "$PREFIX/lib/libmpc.so" ]; then
    echo "MPC already exists!"
else

wget https://ftp.gnu.org/gnu/mpc/mpc-1.4.1.tar.xz
tar xvf mpc-1.4.1.tar.xz
mkdir -p mpc-1.4.1/build
cd mpc-1.4.1/build
../configure --prefix=$PREFIX --with-gnu-ld --with-gmp=$PREFIX --with-mpfr=$PREFIX --enable-static --enable-shared --host=$HOST
make -j$(nproc)
make check
make install
cd $PREFIX
rm -rf mpc-1.4.1*

fi

# building gcc
if [ -e "$PREFIX/bin/$TARGET-gcc" ]; then
    echo "GCC already exists!"
else

if [ ! -e "$PREFIX/gcc-16.2.0" ]; then
    wget https://ftp.gnu.org/gnu/gcc/gcc-16.2.0/gcc-16.2.0.tar.gz
    tar zxvf gcc-16.2.0.tar.gz
fi
mkdir -p gcc-16.2.0/build
cd gcc-16.2.0
python3 <<'PY'
from pathlib import Path

p = Path("libgcc/config/aarch64/cpuinfo.c")
s = p.read_text()

old = """#include <sys/auxv.h>
"""

new = """#include <sys/auxv.h>

#ifdef __FreeBSD__
static unsigned long int
gcc_getauxval (unsigned long int type)
{
  unsigned long int value = 0;
  (void) elf_aux_info ((int) type, &value, sizeof (value));
  return value;
}
#define getauxval gcc_getauxval
#endif
"""

assert s.count(old) == 1, "Could not uniquely locate sys/auxv.h include"

old_defs = """#define AT_HWCAP 16
#define AT_HWCAP2 26
#define AT_HWCAP3 29
#define AT_HWCAP4 30
"""

new_defs = """#ifndef AT_HWCAP
#define AT_HWCAP 16
#endif
#ifndef AT_HWCAP2
#define AT_HWCAP2 26
#endif
#ifndef AT_HWCAP3
#define AT_HWCAP3 29
#endif
#ifndef AT_HWCAP4
#define AT_HWCAP4 30
#endif
"""

assert s.count(old_defs) == 1, "Could not uniquely locate HWCAP definitions"

Path(str(p) + ".orig").write_text(s)

s = s.replace(old, new, 1)
s = s.replace(old_defs, new_defs, 1)

p.write_text(s)

print("Successfully patched", p)
PY
python3 <<'PY'
from pathlib import Path

p = Path("libgcc/unwind-dw2-fde-dip.c")
s = p.read_text()

old = "# define ElfW __ElfN"
new = """# ifndef ElfW
#  define ElfW __ElfN
# endif"""

assert s.count(old) == 1, "Could not uniquely locate ElfW definition"

Path(str(p) + ".orig").write_text(s)

s = s.replace(old, new, 1)
p.write_text(s)

print("Successfully patched", p)
PY
cd build
../configure \
    --build="$BUILD" \
    --host="$HOST" \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --with-sysroot="$SYSROOT" \
    --with-native-system-header-dir=/usr/include \
    --with-gnu-as \
    --with-gnu-ld \
    --enable-languages=c,c++ \
    --enable-threads=posix \
    --enable-shared \
    --disable-nls \
    --disable-bootstrap \
    --disable-libgomp \
    --with-gmp="$PREFIX" \
    --with-mpfr="$PREFIX" \
    --with-mpc="$PREFIX"
LD_LIBRARY_PATH=$PREFIX/lib make -j"$(nproc)" all-gcc
make install-gcc
LD_LIBRARY_PATH=$PREFIX/lib make -j"$(nproc)" all-target-libgcc
make install-target-libgcc

cd "$PREFIX"
rm -rf gcc-16.2.0*

fi

echo "To use $TARGET-gcc, add $PREFIX/bin to your path!"
echo "export PATH="$PATH:$PREFIX/bin""