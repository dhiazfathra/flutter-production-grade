#!/usr/bin/env bash
set -euo pipefail

fail() {
	echo "FAIL: $1"
	exit 1
}

echo "== doctor =="

pinned=$(grep -o '"flutter": *"[^"]*"' .fvmrc | grep -o '[0-9][0-9.]*')
installed=$(fvm flutter --version | awk '/Flutter/{print $2; exit}')
if [ "$pinned" != "$installed" ]; then
	fail ".fvmrc pins Flutter ${pinned} but 'fvm flutter --version' reports ${installed}"
fi
echo "ok: .fvmrc (${pinned}) matches fvm flutter --version"

if [ ! -f config/dev.json ]; then
	fail "config/dev.json is missing"
fi
echo "ok: config/dev.json exists"

before=$(git status --porcelain)
fvm dart run build_runner build --delete-conflicting-outputs >/dev/null
after=$(git status --porcelain)
if [ "$before" != "$after" ]; then
	fail "build_runner build left the tree dirty; commit generated output"
fi
echo "ok: build_runner build leaves the tree clean"

echo "doctor: all checks passed"
