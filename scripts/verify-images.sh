#!/usr/bin/env bash
#
# Verify a wax image set actually works. Runs identically locally (`make verify`)
# and in CI, so local-green == CI-green.
#
# Checks, in order:
#   1. nodeos / cleos report the version the tag claims
#   2. cdt-cpp reports the CDT version the tag claims
#   3. no binary in any image is missing a shared library
#   4. both CDT images can compile a real contract to .wasm + .abi
#
# (3) and (4) exist because waxteam/cdt-node shipped from 2025-12 through
# 2026-09 with neither libz3-4 (clang-9) nor libxml2 (lld/wasm-ld) installed,
# so its compiler and linker were both broken. Nothing caught it, because
# nothing ever compiled a contract with the image we published.
#
# Usage:  WAX_VERSION=ce-v1.3.1wax01 CDT_VERSION=v4.1.1wax01 scripts/verify-images.sh
#
# SKIP_HEAVY=1 drops the checks that need the ~21GB waxteam/cdt builder image
# (and the provenance file, which only that image carries). Set it on a runner
# that cannot hold 21GB -- a GitHub-hosted runner has ~14GB free. The two images
# users actually consume, waxnode and cdt-node, are still fully checked.
#
set -uo pipefail

: "${WAX_VERSION:?set WAX_VERSION (e.g. ce-v1.3.1wax01)}"
: "${CDT_VERSION:?set CDT_VERSION (e.g. v4.1.1wax01)}"

NODE_IMAGE=${NODE_IMAGE:-waxteam/waxnode:${WAX_VERSION}}
CDT_IMAGE=${CDT_IMAGE:-waxteam/cdt:${WAX_VERSION}-${CDT_VERSION}}
CDT_NODE_IMAGE=${CDT_NODE_IMAGE:-waxteam/cdt-node:${WAX_VERSION}-${CDT_VERSION}}

# nodeos reports the CMakeLists version, which is the tag without the `ce-`
# release-line prefix. A mismatch means the tag name and the source disagree --
# exactly the drift that produced `ce-v1.0.3wax01` holding nodeos v1.3.0wax01.
# Override for historical tags that are known-misnamed.
EXPECT_NODEOS=${EXPECT_NODEOS:-${WAX_VERSION#ce-}}
EXPECT_CDT=${EXPECT_CDT:-${CDT_VERSION#v}}

SKIP_HEAVY=${SKIP_HEAVY:-0}

fail=0
pass() { printf '  \033[32mPASS\033[0m  %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; fail=1; }
head2(){ printf '\n\033[1m%s\033[0m\n' "$*"; }

run() { docker run --rm "$@" 2>&1; }

# ---------------------------------------------------------------- versions ---
head2 "versions"

got=$(run "$NODE_IMAGE" nodeos --version | tail -1)
[ "$got" = "$EXPECT_NODEOS" ] \
  && pass "nodeos $got" \
  || bad  "nodeos reported '$got', tag implies '$EXPECT_NODEOS'"

got=$(run "$NODE_IMAGE" cleos version client | tail -1)
[ "$got" = "$EXPECT_NODEOS" ] \
  && pass "cleos $got" \
  || bad  "cleos reported '$got', tag implies '$EXPECT_NODEOS'"

got=$(run "$CDT_NODE_IMAGE" cdt-cpp --version | tail -1)
case "$got" in
  *"$EXPECT_CDT") pass "cdt-cpp $got" ;;
  *)              bad  "cdt-cpp reported '$got', tag implies '$EXPECT_CDT'" ;;
esac

# nodeos must also be usable from the combined image
got=$(run "$CDT_NODE_IMAGE" nodeos --version | tail -1)
[ "$got" = "$EXPECT_NODEOS" ] \
  && pass "nodeos in cdt-node $got" \
  || bad  "nodeos in cdt-node reported '$got', expected '$EXPECT_NODEOS'"

# ------------------------------------------------------- shared libraries ---
head2 "shared libraries (every binary, every image)"

ldd_sweep='
for b in /usr/local/cdt/bin/* /usr/local/wax-blockchain/bin/*; do
  [ -f "$b" ] && [ -x "$b" ] || continue
  m=$(ldd "$b" 2>/dev/null | grep "not found" | awk "{print \$1}" | sort -u | tr "\n" " ")
  [ -n "$m" ] && echo "$(basename "$b"): $m"
done
exit 0'

sweep_images="$NODE_IMAGE $CDT_NODE_IMAGE"
[ "$SKIP_HEAVY" = "1" ] || sweep_images="$NODE_IMAGE $CDT_IMAGE $CDT_NODE_IMAGE"

for img in $sweep_images; do
  missing=$(run "$img" sh -c "$ldd_sweep")
  if [ -z "$missing" ]; then
    pass "no missing libraries in ${img##*/}"
  else
    bad "missing libraries in ${img##*/}:"
    printf '        %s\n' "$missing"
  fi
done

# ------------------------------------------------------- contract compile ---
head2 "contract compile"

FIXTURE_DIR=$(cd "$(dirname "$0")/../test" && pwd)

compile_images="$CDT_NODE_IMAGE"
[ "$SKIP_HEAVY" = "1" ] || compile_images="$CDT_IMAGE $CDT_NODE_IMAGE"

for img in $compile_images; do
  work=$(mktemp -d)
  cp "$FIXTURE_DIR/hello.cpp" "$work/"
  out=$(docker run --rm -v "$work:/work" -w /work "$img" \
          cdt-cpp -abigen -o hello.wasm hello.cpp 2>&1)
  rc=$?
  if [ "$rc" -eq 0 ] && [ -s "$work/hello.wasm" ] && [ -s "$work/hello.abi" ]; then
    pass "${img##*/} compiled hello.wasm ($(stat -c %s "$work/hello.wasm") bytes) + hello.abi"
  else
    bad "${img##*/} could not compile a contract"
    printf '        %s\n' "$(echo "$out" | grep -i error | head -3)"
  fi
  rm -rf "$work"
done

# -------------------------------------------------------------- provenance --
head2 "provenance"

if [ "$SKIP_HEAVY" = "1" ]; then
  printf '  \033[33mSKIP\033[0m  wax-version (needs the cdt builder image; SKIP_HEAVY=1)\n'
else
got=$(run "$CDT_IMAGE" cat /tmp/wax-blockchain/wax-version 2>/dev/null | tail -1)
case "$got" in
  "$WAX_VERSION":[0-9a-f]*) pass "wax-version $got" ;;
  "")                       bad  "wax-version file missing from ${CDT_IMAGE##*/}" ;;
  *)                        bad  "wax-version is '$got', expected '$WAX_VERSION:<commit>'" ;;
esac
fi

# -------------------------------------------------------------------- done --
printf '\n'
if [ "$fail" -eq 0 ]; then
  printf '\033[32mAll checks passed\033[0m for %s / %s\n' "$WAX_VERSION" "$CDT_VERSION"
else
  printf '\033[31mVerification FAILED\033[0m for %s / %s\n' "$WAX_VERSION" "$CDT_VERSION"
fi
exit "$fail"
