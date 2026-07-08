# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is **not** an Android app or a publishable Gradle library. It is a build pipeline that cross-compiles `libmpv` and its native dependencies (FFmpeg, dav1d, libass, libplacebo, etc.) for Android (`arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64`) and packages the resulting `.so` files into flat `.jar` archives (`default-*.jar`, `full-*.jar`, `encoders-gpl-*.jar`). Those jars are attached to GitHub releases and consumed by downstream apps (e.g. media-kit-style Android video players) that unpack the native libs into their own `jniLibs`.

The `libmpv/` Gradle module (referenced from `settings.gradle.kts`) is a **legacy leftover** — its `build.gradle.kts`, Java/JNI sources, and CMake files were deleted in commit `ca0d9d2` ("build"). Only `libmpv/src/main/jniLibs/<abi>/*.so` remains, used purely as the drop location for freshly-built native libraries (`native_dir` in `buildscripts/build.sh`). Do not expect `./gradlew` to build anything meaningful here — the root `build.gradle.kts` / `settings.gradle.kts` / `gradle/libs.versions.toml` are vestigial from when this repo used to publish an AAR to Maven Central.

The real entry point is `buildscripts/*.sh`, driven by CI in `.github/workflows/build.yaml`.

## Build flavors

There are three independent build flavors, each with its own top-level bundle script under `buildscripts/`:

| Flavor | Bundle script | ffmpeg config source | Notes |
|---|---|---|---|
| default | `bundle_default.sh` | `flavors/default.sh` | LGPL-only, decoder/demuxer allowlist, no encoders |
| full | `bundle_full.sh` | `flavors/full.sh` | LGPL-only, all decoders/demuxers/parsers enabled |
| encoders-gpl | `bundle_encoders-gpl.sh` | `flavors/encoders-gpl.sh` | GPL, adds libx264/libvorbis/libvpx encoders, sets `ENCODERS_GPL=1` |

Each bundle script follows the same shape:
1. Wipe `deps/` and `prefix/`, run `download.sh` then the appropriate patch script.
2. Copy the flavor's ffmpeg config into `scripts/ffmpeg.sh` (this is how one `ffmpeg.sh` build script serves three different `./configure` invocations).
3. Run `build.sh` to cross-compile everything for all 4 ABIs.
4. Build `deps/media-kit-android-helper` (a small Android app) via its own Gradle wrapper to produce `libmediakitandroidhelper.so`, and copy it alongside the other libs.
5. Collect all `.so` outputs per-ABI into `temp/lib/<abi>/` and zip each ABI into its own jar.

`ENCODERS_GPL=1` (set inside `bundle_encoders-gpl.sh`) is read by `buildscripts/include/depinfo.sh` to decide whether ffmpeg depends on `libx264`/`libvorbis`/`libvpx` and whether mpv depends on `fftools_ffi`.

## Running a build locally

```sh
cd buildscripts
./bundle_default.sh        # or bundle_full.sh / bundle_encoders-gpl.sh
```

Building a single native dependency without the full pipeline:

```sh
cd buildscripts
./download.sh               # clones/downloads all deps into deps/ (gitignored)
./patch.sh                  # applies buildscripts/patches/<dep>/*.patch via `git apply`
./build.sh <target> --arch <armv7l|arm64|x86|x86_64>   # e.g. ./build.sh mpv --arch arm64
./build.sh <target> -n      # -n / --no-deps: skip building the target's dependencies first
./build.sh <target> --clean # clean that target's build dir first
```

`build.sh` builds all 4 archs when `--arch` is omitted. Dependency ordering comes from the `dep_*` arrays in `buildscripts/include/depinfo.sh` (e.g. `dep_mpv=(ffmpeg libass libplacebo)`), and `build()` recurses into those before building the target itself.

Local build state lives in `buildscripts/deps/` (upstream source checkouts, gitignored), `buildscripts/prefix/<abi>/` (per-ABI sysroot/install prefix, gitignored), and `buildscripts/temp/` (staging dir for jar assembly, gitignored). These are large and already present in a dev environment that has run a build — don't assume a clean checkout has them.

## Dependency versions and pinning

All dependency versions/commits/branches are centralized in **two** files that must be kept in sync when bumping a dependency:

- `buildscripts/include/depinfo.sh` — version numbers (`v_mpv`, `v_ffmpeg`, `v_libplacebo`, ...) and the dependency graph (`dep_mpv=(...)`, `dep_ffmpeg=(...)`, ...).
- `buildscripts/include/download-deps.sh` — the actual `git clone`/`wget` commands that check out those versions (mpv and libx264 are pinned to exact commit hashes via `git reset --hard`, not tags).

## Patches

Upstream sources get patched via plain `git apply` in `patch.sh` (default/full flavors) and `patch-encoders-gpl.sh` (encoders-gpl flavor), reading from `buildscripts/patches/<dep>/*.patch` and `buildscripts/patches-encoders-gpl/<dep>/*.patch` respectively. Both patch sets currently overlap significantly (e.g. `mpv_fence_leak-fix.patch`, `fix_shaderc_vulkan_dismatch.patch`, `ffmpeg-hls-kazumi-combined.patch` exist in both trees) — when fixing a bug that affects both flavors, update the patch in **both** directories.

Patching is destructive: `patch.sh`/`patch-encoders-gpl.sh` run `git reset --hard` in each dep's checkout before applying patches, discarding any local edits made directly inside `buildscripts/deps/<dep>`.

## Cross-compilation environment

`buildscripts/build.sh`'s `loadarch()` sets up the NDK toolchain per ABI (API level 28, clang triples, `nasm` as assembler for x86, 16KB page size linker flags). `buildscripts/include/path.sh` and `setup_prefix()` generate a Meson cross-file (`crossfile.txt`) per prefix dir for dependencies that use Meson (dav1d, libplacebo, fribidi, harfbuzz, libxml2, lcms2, libogg/libvorbis via meson wrapper `.build` shims). Autotools/configure-based deps (ffmpeg, mbedtls, freetype, libass) are driven directly via their own `scripts/<dep>.sh`.

Each `scripts/<dep>.sh` is invoked as `<script> build` or `<script> clean` (see the `build()` function in `build.sh`) and is expected to install into `$prefix_dir` (`buildscripts/prefix/<abi>/`) and, for the final libmpv build, symlink `libmpv.so` into `$native_dir` (`libmpv/src/main/jniLibs/<abi>/`).

## CI

`.github/workflows/build.yaml` runs on Debian (bookworm-slim container) via GitHub Actions, installs Meson from bookworm-backports, sets up JDK 17 + Android SDK + NDK r27c, then runs `bundle_default.sh` with `sudo` stripped out and `download-sdk.sh` swapped for `download-sdk-debian.sh` (see the `sed` calls in the workflow). Output jars are uploaded as workflow artifacts and attached to a draft GitHub release tagged `vnext` on pushes to `main` or manual dispatch with `release: true`.
