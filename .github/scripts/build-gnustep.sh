#!/usr/bin/env bash
# Build an isolated Clang/libobjc2 stack; distro packages use GCC's runtime,
# which lacks the associated-object APIs used by the GUX plugin.
set -eo pipefail

: "${GNUSTEP_PREFIX:?Set GNUSTEP_PREFIX to the dependency install directory}"
export CC=clang CXX=clang++
export LDFLAGS="-fuse-ld=lld"
export PATH="$GNUSTEP_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$GNUSTEP_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="$GNUSTEP_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

sources=$(mktemp -d)
trap 'rm -rf "$sources"' EXIT

fetch() {
    git init -q "$sources/$1"
    git -C "$sources/$1" fetch -q --depth=1 "https://github.com/gnustep/$1.git" "$2"
    git -C "$sources/$1" checkout -q --detach FETCH_HEAD
}

# Pin the stack so an upstream change cannot silently change the CI baseline.
fetch libobjc2 a21ae931e4c186312701d7a4a8e85204955965a6
fetch tools-make e7c0730d54e272b2ff56d508fcb0bcfd9a890985
fetch libs-base c970491758a42f8f1546f09e07c8bd3784ee01e8
fetch libs-gui 662f89071905d712c472a7cd3c956730a493bb6d
fetch libs-back 2c7d5f1917dae3a1e89959e234b47059e71dc70c

cmake -S "$sources/libobjc2" -B "$sources/libobjc2/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$GNUSTEP_PREFIX" \
    -DGNUSTEP_INSTALL_TYPE=NONE -DTESTS=OFF
cmake --build "$sources/libobjc2/build" --parallel 2
cmake --install "$sources/libobjc2/build"

cd "$sources/tools-make"
./configure --prefix="$GNUSTEP_PREFIX" --with-library-combo=ng-gnu-gnu \
    --with-runtime-abi=gnustep-2.2
make install
# GNUstep.sh does not support nounset (-u).
. "$GNUSTEP_PREFIX/share/GNUstep/Makefiles/GNUstep.sh"

for component in libs-base libs-gui libs-back; do
    cd "$sources/$component"
    if [ "$component" = libs-back ]; then
        ./configure --enable-graphics=cairo
    else
        ./configure
    fi
    make -j2
    make install
done
