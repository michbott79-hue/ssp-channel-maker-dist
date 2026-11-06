#!/usr/bin/env bash
# install-ffmpeg-nvenc.sh - install build dependencies and compile FFmpeg with NVIDIA NVENC support.
#
# Builds a dynamic (shared libraries optional) FFmpeg from the official source tree against the
# nv-codec-headers release that matches the installed NVIDIA driver, then proves the result with a
# short GPU encode. Works as root/sudo (system install) or as a normal user (no-sudo mode).
#
# This script never touches an existing system ffmpeg: it installs into its own prefix.
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_VERSION="1.2.0"
readonly FFMPEG_REPO="https://github.com/FFmpeg/FFmpeg.git"
readonly HEADERS_REPO="https://github.com/FFmpeg/nv-codec-headers.git"
readonly DEFAULT_FFMPEG_TAG="n8.1.3"

FFMPEG_TAG="$DEFAULT_FFMPEG_TAG"
HEADERS_TAG=""            # empty = chosen from the driver version
PREFIX=""
BIN_DIR=""
BUILD_DIR=""
JOBS="$(nproc 2>/dev/null || echo 2)"
MODE="auto"               # auto | system | user
ASSUME_YES=0
SHARED=0
KEEP_BUILD=0
SKIP_DEPS=0
SKIP_TEST=0
LOG_FILE=""

die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf '==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Install the build dependencies and compile FFmpeg with NVENC (H.264, HEVC, AV1) support.

Options:
  --prefix DIR         install location (default: /usr/local/ssp-ffmpeg-nvenc as root,
                       \$HOME/.local/ssp-ffmpeg-nvenc otherwise)
  --bin-dir DIR        install only ffmpeg and ffprobe into DIR (absolute path), nothing else.
                       Default when this script sits next to the ssp-channel-maker program:
                       the bin/ folder next to it, so the whole workspace stays in one folder
  --user               no-sudo mode: never install packages, only check them; nasm is fetched
                       without root when missing
  --system             force system mode (needs root or sudo)
  --ffmpeg-tag TAG     FFmpeg release tag to build (default: $DEFAULT_FFMPEG_TAG)
  --headers-tag TAG    nv-codec-headers tag, overrides the choice made from the driver version
  --build-dir DIR      working directory (default: a new directory under \$TMPDIR)
  --jobs N             parallel compile jobs (default: $JOBS)
  --shared             build shared libraries too (default: static libraries, one binary)
  --keep-build         keep the build directory after a successful build
  --skip-deps          do not install or check packages (you took care of them)
  --skip-test          skip the final GPU encode test (build machine without a GPU)
  --yes                do not ask for confirmation
  --version            print the script version
  -h, --help           this help

The NVIDIA driver must already be installed (nvidia-smi works). Nothing is deleted outside the
build directory this script creates.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)       [ $# -ge 2 ] || die "--prefix needs a value"; PREFIX="$2"; shift 2 ;;
    --bin-dir)      [ $# -ge 2 ] || die "--bin-dir needs a value"; BIN_DIR="$2"; shift 2 ;;
    --user)         MODE="user"; shift ;;
    --system)       MODE="system"; shift ;;
    --ffmpeg-tag)   [ $# -ge 2 ] || die "--ffmpeg-tag needs a value"; FFMPEG_TAG="$2"; shift 2 ;;
    --headers-tag)  [ $# -ge 2 ] || die "--headers-tag needs a value"; HEADERS_TAG="$2"; shift 2 ;;
    --build-dir)    [ $# -ge 2 ] || die "--build-dir needs a value"; BUILD_DIR="$2"; shift 2 ;;
    --jobs)         [ $# -ge 2 ] || die "--jobs needs a value"; JOBS="$2"; shift 2 ;;
    --shared)       SHARED=1; shift ;;
    --keep-build)   KEEP_BUILD=1; shift ;;
    --skip-deps)    SKIP_DEPS=1; shift ;;
    --skip-test)    SKIP_TEST=1; shift ;;
    --yes|-y)       ASSUME_YES=1; shift ;;
    --version)      echo "$SCRIPT_VERSION"; exit 0 ;;
    -h|--help)      usage; exit 0 ;;
    *)              usage >&2; die "unknown option: $1" ;;
  esac
done

# Tags are used as git refs and paths: accept only plain release names.
valid_tag() { [[ "$1" =~ ^n[0-9]+(\.[0-9]+){1,3}$ ]]; }
valid_tag "$FFMPEG_TAG" || die "invalid --ffmpeg-tag '$FFMPEG_TAG' (expected e.g. n8.1.3)"
[ -z "$HEADERS_TAG" ] || valid_tag "$HEADERS_TAG" || die "invalid --headers-tag '$HEADERS_TAG' (expected e.g. n13.0.19.1)"
[[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || die "--jobs must be a positive number"

# ---------------------------------------------------------------- preflight

[ "$(uname -s)" = "Linux" ] || die "Linux only"
[ "$(uname -m)" = "x86_64" ] || die "x86_64 only (found $(uname -m))"

OS_ID=""; OS_VERSION=""
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  OS_ID="$(. /etc/os-release && echo "${ID:-}")"
  # shellcheck disable=SC1091
  OS_VERSION="$(. /etc/os-release && echo "${VERSION_ID:-}")"
fi
# Only Ubuntu 24.04 is tested and supported for now (Mich, 2026-11-03).
if [ "$OS_ID" != "ubuntu" ] || [ "$OS_VERSION" != "24.04" ]; then
  warn "only Ubuntu 24.04 is tested (found '${OS_ID:-unknown} ${OS_VERSION:-?}'); the build may fail"
fi

if [ "$MODE" = "auto" ]; then
  if [ "$(id -u)" -eq 0 ]; then MODE="system"; else MODE="user"; fi
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "$PREFIX" ] && [ -z "$BIN_DIR" ] && [ -f "$SCRIPT_DIR/ssp-channel-maker" ]; then BIN_DIR="$SCRIPT_DIR/bin"; fi
[ -z "$PREFIX" ] || [ -z "$BIN_DIR" ] || die "use --prefix or --bin-dir, not both"
[ -z "$BIN_DIR" ] || [ "$SHARED" -eq 0 ] || die "--bin-dir copies two single-file programs: it cannot be used with --shared"
if [ -n "$BIN_DIR" ]; then case "$BIN_DIR" in /*) ;; *) die "--bin-dir must be an absolute path" ;; esac; fi
if [ -z "$PREFIX" ] && [ -z "$BIN_DIR" ]; then
  if [ "$MODE" = "system" ]; then PREFIX="/usr/local/ssp-ffmpeg-nvenc"; else PREFIX="$HOME/.local/ssp-ffmpeg-nvenc"; fi
fi
[ -z "$PREFIX" ] || case "$PREFIX" in /*) ;; *) die "--prefix must be an absolute path" ;; esac

SUDO=""
if [ "$MODE" = "system" ] && [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || die "system mode needs root or sudo (or use --user)"
  SUDO="sudo"
fi

# NVIDIA driver version: nvidia-smi first, /proc as fallback.
DRIVER=""
if command -v nvidia-smi >/dev/null 2>&1; then
  DRIVER="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 | tr -d '[:space:]')" || true
fi
if [ -z "$DRIVER" ] && [ -r /proc/driver/nvidia/version ]; then
  DRIVER="$(grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' /proc/driver/nvidia/version | head -n1)" || true
fi
if [ -z "$DRIVER" ]; then
  if [ "$SKIP_TEST" -eq 1 ] && [ -n "$HEADERS_TAG" ]; then
    warn "no NVIDIA driver found; building with the headers tag you gave, GPU test skipped"
  else
    die "NVIDIA driver not found. Install it first (nvidia-smi must work), or pass --headers-tag and --skip-test to only build."
  fi
fi

# Compare dotted versions: returns 0 when $1 >= $2.
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

# Header tag per driver. Minimum drivers are the ones stated in the README of each
# FFmpeg/nv-codec-headers tag; FFmpeg 8.1 itself needs headers >= 12.1.14.0.
if [ -z "$HEADERS_TAG" ]; then
  if   version_ge "$DRIVER" "610.0";       then HEADERS_TAG="n13.1.15.0"
  elif version_ge "$DRIVER" "570.0";       then HEADERS_TAG="n13.0.19.1"
  elif version_ge "$DRIVER" "550.54.14";   then HEADERS_TAG="n12.2.72.0"
  elif version_ge "$DRIVER" "530.41.03";   then HEADERS_TAG="n12.1.14.0"
  else die "NVIDIA driver $DRIVER is too old for FFmpeg 8.1 NVENC (needs 530.41.03 or newer). Update the driver."
  fi
fi

if [ -z "$BUILD_DIR" ]; then
  BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ssp-ffmpeg-nvenc.XXXXXXXX")"
else
  case "$BUILD_DIR" in /*) ;; *) die "--build-dir must be an absolute path" ;; esac
  mkdir -p "$BUILD_DIR"
  [ -z "$(ls -A "$BUILD_DIR" 2>/dev/null)" ] || die "--build-dir '$BUILD_DIR' is not empty"
  # The build tree feeds `make install` (possibly as root): it must be private to the current user.
  [ -O "$BUILD_DIR" ] || die "--build-dir '$BUILD_DIR' is not owned by you"
  [ -z "$(find "$BUILD_DIR" -maxdepth 0 -perm /022)" ] || die "--build-dir '$BUILD_DIR' is writable by group/others (use chmod 700)"
  # Work in a private subdirectory created fresh, so nothing pre-existing can be reused.
  BUILD_DIR="$(mktemp -d "$BUILD_DIR/ssp.XXXXXXXX")"
fi
LOG_FILE="$BUILD_DIR/build.log"
: > "$LOG_FILE"
# With --bin-dir the full install goes to a private folder inside the build dir; only the two programs are copied out.
if [ -n "$BIN_DIR" ]; then PREFIX="$BUILD_DIR/prefix"; fi

cat <<EOF
ssp-ffmpeg-nvenc $SCRIPT_VERSION
  mode          : $MODE
  OS            : ${OS_ID:-?} ${OS_VERSION:-?}
  NVIDIA driver : ${DRIVER:-none}
  FFmpeg        : $FFMPEG_TAG
  nv-codec-headers: $HEADERS_TAG
  install into  : ${BIN_DIR:-$PREFIX}${BIN_DIR:+ (ffmpeg and ffprobe only)}
  build dir     : $BUILD_DIR (log: $LOG_FILE)
EOF

if [ "$ASSUME_YES" -ne 1 ]; then
  if [ -t 0 ]; then
    read -r -p "Proceed? [y/N] " answer
    case "$answer" in y|Y|yes|YES) ;; *) die "aborted" ;; esac
  else
    die "not interactive: pass --yes to confirm"
  fi
fi

# Log everything from here on; keep a readable summary on the terminal.
run() { "$@" >>"$LOG_FILE" 2>&1 || { echo "FAILED: $*" >&2; echo "--- last log lines ---" >&2; tail -n 25 "$LOG_FILE" >&2; die "step failed, full log: $LOG_FILE"; }; }

# ---------------------------------------------------------------- dependencies

readonly BUILD_PACKAGES=(build-essential git curl ca-certificates pkg-config nasm yasm libfreetype-dev libharfbuzz-dev libzimg-dev)
NASM_BIN_DIR=""

install_deps() {
  info "Build dependencies"
  local missing=() cmd
  for cmd in gcc make git curl pkg-config; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if [ "$MODE" = "system" ]; then
    command -v apt-get >/dev/null 2>&1 || die "apt-get not found: install ${BUILD_PACKAGES[*]} yourself and use --skip-deps"
    run $SUDO apt-get update
    run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${BUILD_PACKAGES[@]}"
  else
    if [ "${#missing[@]}" -gt 0 ]; then
      die "missing tools: ${missing[*]}. Ask an administrator to install: ${BUILD_PACKAGES[*]} (or run this script as root)"
    fi
    # drawtext needs libfreetype + libharfbuzz (FFmpeg 8) and zscale needs libzimg: they are linked in, so the dev files must exist.
    local lib
    for lib in freetype2 harfbuzz zimg; do
      pkg-config --exists "$lib" || die "development files for $lib not found. Ask an administrator to install: ${BUILD_PACKAGES[*]} (or run this script as root)"
    done
    if ! command -v nasm >/dev/null 2>&1; then
      info "nasm not found: fetching it without root"
      if command -v apt >/dev/null 2>&1; then
        mkdir -p "$BUILD_DIR/nasm-deb"
        # Failure here is not fatal: the build falls back to --disable-x86asm.
        if ( cd "$BUILD_DIR/nasm-deb" && apt download nasm ) >>"$LOG_FILE" 2>&1 \
           && dpkg -x "$BUILD_DIR"/nasm-deb/nasm_*.deb "$BUILD_DIR/nasm-root" >>"$LOG_FILE" 2>&1; then
          NASM_BIN_DIR="$BUILD_DIR/nasm-root/usr/bin"
        fi
      fi
      if [ -z "$NASM_BIN_DIR" ] || [ ! -x "$NASM_BIN_DIR/nasm" ]; then
        warn "nasm unavailable: building without x86 assembly (software filters will be slower, NVENC is unaffected)"
        NASM_BIN_DIR=""
        NO_ASM=1
      fi
    fi
  fi
}

NO_ASM=0
if [ "$SKIP_DEPS" -eq 0 ]; then install_deps; else info "Skipping dependency step"; fi
[ -z "$NASM_BIN_DIR" ] || export PATH="$NASM_BIN_DIR:$PATH"
for cmd in gcc make git pkg-config; do
  command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' is required"
done
if ! command -v nasm >/dev/null 2>&1 && ! command -v yasm >/dev/null 2>&1; then NO_ASM=1; fi

# ---------------------------------------------------------------- nv-codec-headers

HEADERS_PREFIX="$BUILD_DIR/headers"
info "nv-codec-headers $HEADERS_TAG"
run git clone --quiet --depth 1 --branch "$HEADERS_TAG" "$HEADERS_REPO" "$BUILD_DIR/nv-codec-headers"
run make -C "$BUILD_DIR/nv-codec-headers" install PREFIX="$HEADERS_PREFIX"
# The pkg-config file lives in lib/pkgconfig (older tags) or share/pkgconfig.
export PKG_CONFIG_PATH="$HEADERS_PREFIX/lib/pkgconfig:$HEADERS_PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
pkg-config --exists ffnvcodec || die "ffnvcodec.pc not found after installing the headers"

# ---------------------------------------------------------------- FFmpeg

info "FFmpeg $FFMPEG_TAG (source)"
run git clone --quiet --depth 1 --branch "$FFMPEG_TAG" "$FFMPEG_REPO" "$BUILD_DIR/ffmpeg-src"

CONFIGURE_ARGS=(
  "--prefix=$PREFIX"
  --enable-gpl --enable-nvenc --enable-ffnvcodec
  --enable-libfreetype --enable-libharfbuzz --enable-libzimg
  --disable-debug --disable-doc --disable-ffplay
)
if [ "$SHARED" -eq 1 ]; then CONFIGURE_ARGS+=(--enable-shared --disable-static); else CONFIGURE_ARGS+=(--enable-static --disable-shared); fi
[ "$NO_ASM" -eq 0 ] || CONFIGURE_ARGS+=(--disable-x86asm)

info "Configure"
( cd "$BUILD_DIR/ffmpeg-src" && run ./configure "${CONFIGURE_ARGS[@]}" )
info "Compile with $JOBS jobs (a few minutes)"
( cd "$BUILD_DIR/ffmpeg-src" && run make -j"$JOBS" )

info "Install into ${BIN_DIR:-$PREFIX}"
if [ "$MODE" = "system" ] && [ -z "$BIN_DIR" ]; then
  ( cd "$BUILD_DIR/ffmpeg-src" && run $SUDO mkdir -p "$PREFIX" && run $SUDO make install )
else
  ( cd "$BUILD_DIR/ffmpeg-src" && run mkdir -p "$PREFIX" && run make install )
fi

# ---------------------------------------------------------------- self-test

FFMPEG_BIN="$PREFIX/bin/ffmpeg"
[ -x "$FFMPEG_BIN" ] || die "ffmpeg not found at $FFMPEG_BIN after install"
if [ "$SHARED" -eq 1 ]; then export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; fi

info "Self-test"
ENCODERS="$("$FFMPEG_BIN" -hide_banner -encoders 2>/dev/null)"
for enc in h264_nvenc hevc_nvenc av1_nvenc; do
  grep -q "$enc" <<<"$ENCODERS" || die "$enc missing from the built ffmpeg"
done
echo "  encoders: h264_nvenc hevc_nvenc av1_nvenc present"
FILTERS="$("$FFMPEG_BIN" -hide_banner -filters 2>/dev/null)"
for flt in drawtext zscale tonemap bwdif; do
  grep -qE "^ [A-Z.]+ +$flt " <<<"$FILTERS" || die "filter $flt missing from the built ffmpeg"
done
echo "  filters: drawtext zscale tonemap bwdif present"
# CPU-only filter runs (no GPU needed). drawtext without fontconfig needs a font file: use the first common one found.
FONT_FILE=""
for f in /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf /usr/share/fonts/truetype/freefont/FreeSans.ttf; do
  if [ -r "$f" ]; then FONT_FILE="$f"; break; fi
done
if [ -n "$FONT_FILE" ]; then
  "$FFMPEG_BIN" -hide_banner -loglevel error -f lavfi -i "color=c=black:s=320x180:r=25:d=1,format=yuv420p" \
      -vf "drawtext=fontfile=$FONT_FILE:text=SSP:x=10:y=10:fontsize=24:fontcolor=white" -f null - >>"$LOG_FILE" 2>&1 \
    || die "the drawtext test failed. See $LOG_FILE"
else
  warn "no common font file found: drawtext run skipped (the filter is present)"
fi
"$FFMPEG_BIN" -hide_banner -loglevel error -f lavfi -i "testsrc2=s=320x180:r=25:d=1,format=yuv420p10le" \
    -vf "zscale=tin=smpte2084:min=bt2020nc:pin=bt2020:rin=tv:t=linear:m=bt2020nc:p=bt2020:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=hable,zscale=t=bt709:m=bt709:r=tv,format=yuv420p" -f null - >>"$LOG_FILE" 2>&1 \
  || die "the zscale/tonemap test failed. See $LOG_FILE"
echo "  filter run: drawtext and zscale+tonemap OK"

if [ "$SKIP_TEST" -eq 1 ]; then
  warn "GPU encode test skipped"
else
  "$FFMPEG_BIN" -hide_banner -loglevel error -f lavfi -i testsrc2=s=1920x1080:r=25:d=2 \
      -c:v h264_nvenc -b:v 4000k -f null - >>"$LOG_FILE" 2>&1 \
    || die "the GPU encode test failed (driver/headers mismatch or no GPU access?). See $LOG_FILE"
  echo "  GPU encode: OK (2 s of 1080p H.264 through NVENC)"
fi

if [ -n "$BIN_DIR" ]; then
  run mkdir -p "$BIN_DIR"
  for prog in ffmpeg ffprobe; do
    [ -x "$PREFIX/bin/$prog" ] || die "$prog not found at $PREFIX/bin/$prog after install"
    # copy to a temporary name, then rename: a running ffmpeg is never overwritten in place
    run install -m 0755 "$PREFIX/bin/$prog" "$BIN_DIR/.$prog.new"
    run mv -f -- "$BIN_DIR/.$prog.new" "$BIN_DIR/$prog"
  done
fi

if [ "$KEEP_BUILD" -eq 1 ]; then
  info "Build directory kept: $BUILD_DIR"
else
  # Only the directory this script created itself is removed, by exact path.
  rm -rf -- "$BUILD_DIR"
fi

cat <<EOF

Done. FFmpeg with NVENC is installed in:
  ${BIN_DIR:-$PREFIX/bin}/ffmpeg
  ${BIN_DIR:-$PREFIX/bin}/ffprobe
Add it to your PATH or pass these two paths to the tools that need them. Your system ffmpeg, if any, is untouched.
EOF
