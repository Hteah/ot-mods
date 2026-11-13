#!/usr/bin/env bash
# OT SAMPLERS installer: builds an Octatrack MKI OS image with the four sampler
# machines (SAMPLER, RESAMPLE, LOOPER, RELOOPER) on your own computer.
#
# What it does, in order:
#   1. clones octabam (github.com/sambanks/octabam, MIT) at the commit these
#      machines were built and tested against
#   2. copies this repo's overlay/ on top (the SMPL module + the "samplers" remix)
#   3. installs the build tools (Homebrew on macOS, apt on Debian/Ubuntu/WSL2)
#   4. downloads the official Octatrack OS 1.40C from Elektron's own site
#      (nothing from Elektron is stored in this repo)
#   5. builds the image and puts OCTATRACK_SAMPLERS<n>.bin in ./dist
#   6. optionally copies it to your Octatrack's CF card (--card /Volumes/NAME)
#
# Usage:
#   ./install.sh                       # build into ./dist
#   ./install.sh --card /Volumes/OCTA  # build, then copy to the CF card
#   ./install.sh --build 2             # version number shown on the OT (default 1)
#   ./install.sh --dir ~/somewhere     # where octabam is cloned (default ./work/octabam)
#
# Flash it: CF card in the OT, PROJECT > SYSTEM > OS UPGRADE, pick the file.
# Undo it: flash the stock OCTATRACK_OS1.40C.bin the same way (it is in
# work/octabam/downloads/extracted after a build). See README.md "Going back".
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OCTABAM_URL="https://github.com/sambanks/octabam.git"
OCTABAM_COMMIT="$(tr -d '[:space:]' < "$HERE/OCTABAM_COMMIT")"
DIR="$HERE/work/octabam"
BUILD=1
CARD=""

while [ $# -gt 0 ]; do
  case "$1" in
    --card)  CARD="${2:?--card needs a path, e.g. /Volumes/OCTATRACK}"; shift 2 ;;
    --build) BUILD="${2:?--build needs a number}"; shift 2 ;;
    --dir)   DIR="${2:?--dir needs a path}"; shift 2 ;;
    -h|--help) sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
done
case "$BUILD" in ''|*[!0-9]*) echo "--build must be a number" >&2; exit 1 ;; esac
VERSION="SAMPLERS$BUILD"
[ ${#VERSION} -le 15 ] || { echo "--build too long" >&2; exit 1; }

say() { printf '\n== %s\n' "$*"; }

# --- 1. octabam at the pinned commit -----------------------------------------
command -v git >/dev/null || { echo "git is required (macOS: xcode-select --install)" >&2; exit 1; }
if [ ! -d "$DIR/.git" ]; then
  say "cloning octabam into $DIR"
  mkdir -p "$(dirname "$DIR")"
  git clone --quiet "$OCTABAM_URL" "$DIR"
fi
cd "$DIR"
if [ -n "$(git status --porcelain --untracked-files=no)" ] && \
   [ "$(git rev-parse HEAD)" != "$OCTABAM_COMMIT" ]; then
  echo "$DIR has local changes and is not at $OCTABAM_COMMIT; use --dir for a fresh folder" >&2
  exit 1
fi
say "octabam @ ${OCTABAM_COMMIT:0:8}"
git fetch --quiet origin "$OCTABAM_COMMIT" 2>/dev/null || git fetch --quiet origin
git checkout --quiet --force "$OCTABAM_COMMIT"
git submodule update --init --quiet

# --- 2. the overlay ------------------------------------------------------------
say "adding the sampler machines (overlay/)"
cp -R "$HERE/overlay/." "$DIR/"

# --- 3. tools --------------------------------------------------------------------
say "build tools"
case "$(uname -s)" in
  Darwin) make setup-mac ;;
  Linux)  make setup-linux ;;
  *) echo "macOS or Linux (incl. WSL2) only" >&2; exit 1 ;;
esac
command -v uv >/dev/null || { echo "uv not found after setup" >&2; exit 1; }
uv sync --quiet --extra emu   # numpy is in the emu extra; recon uses it
export PATH="$DIR/.venv/bin:$PATH"

# --- 4. your own copy of the stock OS -------------------------------------------
if [ ! -f downloads/extracted/OCTATRACK_OS1.40C.syx ]; then
  say "downloading Octatrack OS 1.40C from elektron.se"
  make os
fi
if [ ! -f out/raw/section_3_MAIN_OS.bin ]; then
  say "unpacking the stock OS"
  make recon
fi

# --- 5. build ----------------------------------------------------------------------
say "building $VERSION (a few minutes)"
make image REMIX=samplers BUILD="$BUILD" VERSION="$VERSION"
mkdir -p "$HERE/dist"
BIN="$HERE/dist/OCTATRACK_$VERSION.bin"
cp "out/OCTATRACK_$VERSION.bin" "$BIN"
cp "out/OCTATRACK_OS1.40C_$VERSION.syx" "$HERE/dist/" 2>/dev/null || true
SHA=$(shasum -a 256 "$BIN" | awk '{print $1}')

# --- 6. card ---------------------------------------------------------------------
if [ -n "$CARD" ]; then
  [ -d "$CARD" ] || { echo "card not found at $CARD" >&2; exit 1; }
  say "copying to $CARD"
  cp "$BIN" "$CARD/"
  CSHA=$(shasum -a 256 "$CARD/$(basename "$BIN")" | awk '{print $1}')
  [ "$CSHA" = "$SHA" ] || { echo "copy on the card does not match (sha256) -- copy it again" >&2; exit 1; }
  echo "verified on the card. Eject it before pulling it out."
fi

cat <<EOF

Done.
  image:  $BIN
  sha256: $SHA

Flash it (Octatrack MKI):
  1. Copy the .bin to the root of the CF card${CARD:+ (done)} and put the card in the Octatrack.
  2. PROJECT > SYSTEM > OS UPGRADE, choose OCTATRACK_$VERSION.bin, confirm.
  3. After it restarts, PROJECT > SYSTEM > OS VERSION should read $VERSION.
     (If it still reads 1.40C: power off and on, and do OS UPGRADE again.)
Going back to stock: README.md, "Going back".
EOF
