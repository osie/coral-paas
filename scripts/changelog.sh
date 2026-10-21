#!/bin/sh
set -eu

usage="usage: changelog.sh <version> <date> <release notes> [changelog]"
version=${1:?$usage}
date=${2:?$usage}
notes=${3:?$usage}
file=${4:-CHANGELOG.md}

if grep -q "^## \[$version\]" "$file"; then
	echo "$file already has a section for $version"
	exit 0
fi
[ -s "$notes" ] || {
	echo "changelog.sh: $notes is missing or empty" >&2
	exit 1
}

section=$(mktemp)
out=$(mktemp)
trap 'rm -f "$section" "$out"' EXIT

{
	printf '## [%s] - %s\n\n' "$version" "$date"
	awk '/^```/ { fence = !fence } !fence && /^#/ { $0 = "#" $0 } { print }' "$notes"
	printf '\n'
} >"$section"

awk -v section="$section" -v ref="[$version]: https://github.com/osie/coral-paas/releases/tag/v$version" '
	function emit(   line) { while ((getline line < section) > 0) print line; placed = 1 }
	!placed && /^## \[/ { emit() }
	!linked && /^\[[0-9][^]]*\]: / { if (!placed) emit(); print ref; linked = 1 }
	{ print }
	END {
		if (!placed) { print ""; emit() }
		if (!linked) print ref
	}' "$file" >"$out"
cat "$out" >"$file"
echo "added $version to $file"
