#!/bin/bash -e

. ./include/depinfo.sh

[ -z "$WGET" ] && WGET=wget

mkdir -p deps && cd deps

# mbedtls
[ ! -d mbedtls ] && git clone --depth 1 --branch v$v_mbedtls https://github.com/Mbed-TLS/mbedtls.git mbedtls

# dav1d
[ ! -d dav1d ] && git clone --depth 1 --branch $v_dav1d https://code.videolan.org/videolan/dav1d.git dav1d

# libxml2
[ ! -d libxml2 ] && git clone --depth 1 --branch v$v_libxml2 --recursive https://github.com/GNOME/libxml2.git libxml2

# libogg
[ ! -d libogg ] && $WGET https://github.com/xiph/ogg/releases/download/v${v_libogg}/libogg-${v_libogg}.tar.gz && tar -xf libogg-${v_libogg}.tar.gz && mv libogg-${v_libogg} libogg && rm libogg-${v_libogg}.tar.gz

# libvorbis
[ ! -d libvorbis ] && $WGET https://github.com/xiph/vorbis/releases/download/v${v_libvorbis}/libvorbis-${v_libvorbis}.tar.gz && tar -xf libvorbis-${v_libvorbis}.tar.gz && mv libvorbis-${v_libvorbis} libvorbis && rm libvorbis-${v_libvorbis}.tar.gz

# libvpx
[ ! -d libvpx ] && git clone --depth 1 --branch v$v_libvpx https://gitlab.freedesktop.org/gstreamer/meson-ports/libvpx.git

# libx264
[ ! -d libx264 ] && git clone https://code.videolan.org/videolan/x264.git libx264 && cd libx264 && git reset --hard 023112c6f2f575c72e9f26274d183b70996fb542 && cd ..

# ffmpeg
[ ! -d ffmpeg ] && git clone --depth 1 --branch release/$v_ffmpeg https://github.com/FFmpeg/FFmpeg.git ffmpeg

# freetype2
[ ! -d freetype ] && git clone --depth 1 --branch VER-$v_freetype https://gitlab.freedesktop.org/freetype/freetype.git freetype

# fribidi
[ ! -d fribidi ] && git clone --depth 1 --branch v$v_fribidi https://github.com/fribidi/fribidi.git fribidi

# harfbuzz
[ ! -d harfbuzz ] && git clone --depth 1 --branch $v_harfbuzz https://github.com/harfbuzz/harfbuzz.git harfbuzz

# libass
[ ! -d libass ] && git clone --depth 1 --branch $v_libass https://github.com/libass/libass.git libass

# lcms2
[ ! -d lcms2 ] && git clone --depth 1 -b $v_lcms2 https://github.com/mm2/Little-CMS.git lcms2

# shaderc
mkdir -p shaderc
cat >shaderc/README <<'HEREDOC'
Shaderc sources are provided by the NDK.
see <ndk>/sources/third_party/shaderc
HEREDOC

# libplacebo
[ ! -d libplacebo ] && git clone --depth 1 --branch v$v_libplacebo --recurse-submodules https://code.videolan.org/videolan/libplacebo.git libplacebo

# mpv
[ ! -d mpv ] && git clone https://github.com/mpv-player/mpv.git mpv && cd mpv && git reset --hard 32a164cc017acab50389f2194f720ccfd0b01a28 && cd ..

# fftools_ffi
[ ! -d fftools_ffi ] && git clone --branch main https://github.com/moffatman/fftools-ffi.git fftools_ffi && cd fftools_ffi && git reset --hard 10070acb2c090edda86dba431f6c281145ceb221 && cd ..

# media-kit-android-helper
[ ! -d media-kit-android-helper ] && git clone --branch main https://github.com/Predidit/media-kit-android-helper.git && cd media-kit-android-helper && git reset --hard b768ce102cfa9b5ddec618bb939d689d1b0899fa && cd ..

cd ..
