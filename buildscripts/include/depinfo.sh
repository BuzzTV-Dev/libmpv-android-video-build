#!/bin/bash -e

## Dependency versions

v_sdk=9123335_latest
v_ndk=27.2.12479018
v_sdk_build_tools=34.0.0

v_libass=0.17.5
v_harfbuzz=14.2.1
v_fribidi=1.0.16
v_freetype=2-14-3
v_mbedtls=3.6.7
v_dav1d=1.5.3
v_libxml2=2.15.3
v_ffmpeg=8.1
v_ffmpeg_commit=38b88335f99e76ed89ff3c93f877fdefce736c13
v_mpv=41f6a645068483470267271e1d09966ca3b9f413
v_libplacebo=7.360.1
v_lcms2=lcms2.19.1
v_libogg=1.3.6
v_libvorbis=1.3.7
v_libvpx=1.15.2


## Dependency tree
# I would've used a dict but putting arrays in a dict is not a thing

dep_mbedtls=()
dep_dav1d=()
dep_libvorbis=(libogg)
if [ -n "$ENCODERS_GPL" ]; then
	dep_ffmpeg=(mbedtls dav1d libxml2 libvorbis libvpx libx264)
else
	dep_ffmpeg=(mbedtls dav1d libxml2)
fi
dep_freetype2=()
dep_fribidi=()
dep_harfbuzz=()
dep_libass=(freetype fribidi harfbuzz)
dep_lua=()
dep_shaderc=()
dep_libplacebo=(shaderc lcms2)
if [ -n "$ENCODERS_GPL" ]; then
	dep_mpv=(ffmpeg libass libplacebo fftools_ffi)
else
	dep_mpv=(ffmpeg libass libplacebo)
fi
