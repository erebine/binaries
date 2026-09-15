#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# check-license.sh -- fail when the license files this repository serves stop
# being the texts the release binaries are distributed under.
#
# Why this exists
# ---------------
# This repository holds no source. Its licensing weight is carried entirely by
# two files, and both are easy to break without anyone noticing:
#
#   LICENSE is a copy, not an original. Its source of truth is Erebine/
#   platform's Resources/licensing/erebine-binaries-MIT.txt, and it is the
#   text the erectl, EIM and EEM binaries are distributed under. It is a plain
#   MIT grant plus three things that are not MIT boilerplate: the trademark
#   carve-out, the pointer to the third-party notices, and the canonical
#   statement of the licensing model. An edit here -- a clause softened, a
#   sentence dropped, the grant re-wrapped by an editor -- silently changes
#   the terms readers believe the binaries carry.
#
#   THIRD_PARTY_NOTICES is deliberately a pointer, not a snapshot. Notices are
#   generated per release from the exact package versions that release links,
#   and are attached to the release and printed by the binaries. A generated
#   snapshot committed here would describe one release forever and be wrong
#   for every later one, so this file must keep pointing at the release and
#   must not become a copy.
#
# The canonical text is pinned in this script rather than fetched, so the
# check needs no token and no network and does not break when platform moves
# or when a release is retagged. When platform's text changes, update
# CANONICAL_LICENSE here in the same change that updates LICENSE.
#
# Usage
# -----
#   scripts/check-license.sh              # check the repository
#   scripts/check-license.sh --self-test  # run against fixtures
#
# Exit status: 0 pass, 1 check failed, 2 usage error.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Erebine/platform Resources/licensing/erebine-binaries-MIT.txt, byte for
# byte. LICENSE is a copy of this file, so the comparison is exact: a re-wrap
# is a failure, because a copy that has been re-wrapped has been edited.
read -r -d '' CANONICAL_LICENSE <<'TXT' || true
MIT License

Copyright (c) 2026 Kevin Carter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Trademarks are not licensed under this license. See https://erebine.ai/trademark.
Third-party components: see THIRD_PARTY_NOTICES.

Erebine is MIT-licensed agents, an open API, a proprietary control plane.
The erectl client and the EIM and EEM agents are distributed as MIT-licensed
binaries. The Erebine platform (router, control plane, frontend) is proprietary.
Documentation and design papers are published under CC BY 4.0.
TXT

# What THIRD_PARTY_NOTICES must keep saying to remain a usable pointer: where
# the per-release notices are attached, and how to print them from a binary
# already on disk.
NOTICES_POINTERS=(
  "https://github.com/Erebine/binaries/releases"
  "erectl license"
)

# Runs every check under ROOT. Prints one line per check and returns 0 when
# all of them pass.
check_tree() {
  local root="$1" failed=0
  local license="$root/LICENSE" notices="$root/THIRD_PARTY_NOTICES"

  if [ ! -s "$license" ]; then
    echo "FAIL LICENSE: missing or empty"
    failed=1
  elif printf '%s\n' "$CANONICAL_LICENSE" | diff -u - "$license" >/dev/null; then
    echo "ok   LICENSE: matches the canonical binaries license text"
  else
    echo "FAIL LICENSE: differs from the canonical binaries license text"
    printf '%s\n' "$CANONICAL_LICENSE" | diff -u --label canonical - \
      --label LICENSE "$license" | sed 's/^/     /' || true
    failed=1
  fi

  if [ ! -s "$notices" ]; then
    echo "FAIL THIRD_PARTY_NOTICES: missing or empty"
    failed=1
  else
    local pointer
    for pointer in "${NOTICES_POINTERS[@]}"; do
      if grep -qF -- "$pointer" "$notices"; then
        echo "ok   THIRD_PARTY_NOTICES: points at $pointer"
      else
        echo "FAIL THIRD_PARTY_NOTICES: no longer points at $pointer"
        failed=1
      fi
    done
    # A generated per-release snapshot is a wall of copyright lines and SPDX
    # identifiers. This file must stay a pointer: a snapshot committed here
    # would describe one release forever.
    if grep -qE '^[[:space:]]*(Copyright \(c\)|SPDX-License-Identifier:)' "$notices"; then
      echo "FAIL THIRD_PARTY_NOTICES: looks like a generated per-release snapshot"
      echo "     This file points at the notices attached to each release; it"
      echo "     does not carry them. A snapshot here ages into a false claim."
      failed=1
    else
      echo "ok   THIRD_PARTY_NOTICES: still a pointer, not a snapshot"
    fi
  fi

  local file
  for file in "$license" "$notices" "$root/README.md"; do
    [ -f "$file" ] || continue
    if LC_ALL=C grep -q '[^[:print:][:space:]]' "$file"; then
      echo "FAIL ${file#"$root"/}: non-ASCII bytes"
      LC_ALL=C grep -n '[^[:print:][:space:]]' "$file" | head -5 | sed 's/^/     /'
      failed=1
    else
      echo "ok   ${file#"$root"/}: ASCII only"
    fi
  done

  return "$failed"
}

# Builds fixture trees and proves the check fails on a softened MIT clause, a
# dropped trademark carve-out, a drifted licensing statement, a re-wrapped
# copy, a missing notices pointer, a notices snapshot, and a non-ASCII byte.
self_test() {
  local tmp status=0 case_name
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  local good="$tmp/good"
  mkdir -p "$good"
  printf '%s\n' "$CANONICAL_LICENSE" >"$good/LICENSE"
  cat >"$good/THIRD_PARTY_NOTICES" <<'TXT'
THIRD-PARTY NOTICES

Notices are generated for every release and are attached to it:
https://github.com/Erebine/binaries/releases
They are printed by the binaries: `erectl license`.
TXT
  printf '# Binaries\n' >"$good/README.md"

  if check_tree "$good" >/dev/null; then
    echo "self-test ok   the canonical texts pass"
  else
    echo "self-test FAIL the canonical texts should pass"
    check_tree "$good" || true
    status=1
  fi

  for case_name in softened-grant no-trademark-line drifted-statement rewrapped \
                   no-license notices-missing-pointer notices-snapshot non-ascii; do
    local bad="$tmp/$case_name"
    cp -r "$good" "$bad"
    case "$case_name" in
      softened-grant)
        sed -i 's/without restriction, including/for non-commercial use only, including/' \
          "$bad/LICENSE" ;;
      no-trademark-line)
        sed -i '/^Trademarks are not licensed/d' "$bad/LICENSE" ;;
      drifted-statement)
        sed -i 's/a proprietary control plane/an open control plane/' "$bad/LICENSE" ;;
      rewrapped)
        # One paragraph re-flowed: same words, different line breaks.
        sed -i 's/^Third-party components: see THIRD_PARTY_NOTICES\.$/Third-party components:\nsee THIRD_PARTY_NOTICES./' \
          "$bad/LICENSE" ;;
      no-license)
        rm -f "$bad/LICENSE" ;;
      notices-missing-pointer)
        sed -i '/releases$/d' "$bad/THIRD_PARTY_NOTICES" ;;
      notices-snapshot)
        printf 'Copyright (c) 2026 swift-nio authors\n' >>"$bad/THIRD_PARTY_NOTICES" ;;
      non-ascii)
        printf 'Copyright \302\251 2026\n' >>"$bad/THIRD_PARTY_NOTICES" ;;
    esac
    if check_tree "$bad" >/dev/null 2>&1; then
      echo "self-test FAIL $case_name should fail"
      status=1
    else
      echo "self-test ok   $case_name fails"
    fi
  done
  return "$status"
}

case "${1:-}" in
  "") check_tree "$REPO_ROOT" ;;
  --self-test) self_test ;;
  *) echo "usage: $0 [--self-test]" >&2; exit 2 ;;
esac
