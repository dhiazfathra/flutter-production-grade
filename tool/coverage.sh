#!/usr/bin/env bash
set -euo pipefail

# Exclusions are listed explicitly, never globbed away silently (ADR-0010).
# `coverage:remove_from_lcov` does not exist in any published `coverage` release
# (verified against pub.dev, latest is 1.15.1: only collect/format_coverage ship
# as executables) so exclusion uses the `remove_from_coverage` package instead,
# which does the same job against regex patterns on the lcov SF: paths.
# NOTE: entries below are regex (matched against each SF: path with RegExp),
# not glob — `remove_from_coverage` has no glob support, so `**/` etc. would
# silently never match.
EXCLUDE=(
	'\.g\.dart$'
	'\.freezed\.dart$'
	'^lib/l10n/generated/'
	'^lib/core/data/services/local/connection/web\.dart$'
	'^lib/core/platform/url_strategy_web\.dart$'
)

cp coverage/lcov.info coverage/lcov.cleaned.info
fvm dart run remove_from_coverage:remove_from_coverage \
	-f coverage/lcov.cleaned.info \
	"${EXCLUDE[@]/#/--remove=}"

total=$(awk -F: '/^LF:/{f+=$2} /^LH:/{h+=$2} END{printf "%d %d", h, f}' coverage/lcov.cleaned.info)
hit=${total% *}
found=${total#* }

echo "covered ${hit}/${found}"
if [ "$hit" -ne "$found" ]; then
	echo "FAIL: coverage is not 100% of measured lines"
	fvm dart run coverage:format_coverage --lcov --in coverage/lcov.cleaned.info \
		--report-on lib 2>/dev/null || true
	exit 1
fi
