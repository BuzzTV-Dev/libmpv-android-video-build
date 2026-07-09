#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

[ -f configure ] || ./autogen.sh

mkdir -p _build$ndk_suffix
cd _build$ndk_suffix

# the AC_FUNC_MALLOC/AC_FUNC_REALLOC run tests can't execute when
# cross-compiling and would redirect malloc/realloc to unimplemented
# rpl_* wrappers, so answer them ahead of time
../configure \
	CFLAGS=-fPIC \
	ac_cv_func_malloc_0_nonnull=yes \
	ac_cv_func_realloc_0_nonnull=yes \
	--host=$ndk_triple \
	--enable-static \
	--disable-shared \
	--disable-nls \
	--disable-v4l \
	--disable-dvb \
	--disable-bktr \
	--disable-proxy \
	--disable-tests \
	--disable-examples \
	--without-doxygen \
	--without-x

make -C src -j$cores
make -C src DESTDIR="$prefix_dir" install
make DESTDIR="$prefix_dir" install-pkgconfigDATA
