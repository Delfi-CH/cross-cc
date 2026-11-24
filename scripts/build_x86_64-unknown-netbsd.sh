#!/usr/bin/env bash

# general setup stuff
set -euo pipefail

source "$BASEDIR/scripts/vars_x86_64-unknown-netbsd.sh"

cd "$BASEDIR"

mkdir -p "$PREFIX"
mkdir -p "$SYSROOT"

# aquire a netbsd sysroot
if [ -e "$SYSROOT/usr" ]; then
    echo "Sysroot already exists!"
else

wget https://ftp.uni-erlangen.de/netbsd/NetBSD-11.1/amd64/binary/sets/base.tar.xz 
tar -xJf base.tar.xz -C "$SYSROOT"
rm base.tar.xz 

wget https://ftp.uni-erlangen.de/netbsd/NetBSD-11.1/amd64/binary/sets/comp.tar.xz 
tar -xJf comp.tar.xz  -C "$SYSROOT"
rm comp.tar.xz

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
make -j$JOBS
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
make -j$JOBS
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
make -j$JOBS
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
make -j$JOBS
make check
make install
cd $PREFIX
rm -rf mpc-1.4.1*

fi

# building gcc
if [ -e "$PREFIX/bin/$TARGET-gcc" ]; then
    echo "GCC already exists!"
else

wget https://ftp.gnu.org/gnu/gcc/gcc-16.2.0/gcc-16.2.0.tar.gz
tar zxvf gcc-16.2.0.tar.gz
mkdir -p gcc-16.2.0/build
cd gcc-16.2.0/build
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
    --disable-multilib \
    --with-gmp="$PREFIX" \
    --with-mpfr="$PREFIX" \
    --with-mpc="$PREFIX"
LD_LIBRARY_PATH=$PREFIX/lib make -j"$JOBS" all-gcc
make install-gcc
LD_LIBRARY_PATH=$PREFIX/lib make -j"$JOBS" all-target-libgcc
make install-target-libgcc

cd "$PREFIX"
rm -rf gcc-16.2.0*

fi

echo "To use $TARGET-gcc, add $PREFIX/bin to your path!"
echo "export PATH="$PATH:$PREFIX/bin""