#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

bad() {
	echo "FAIL: $*" >&2
	echo "--- $work/CHANGELOG.md" >&2
	cat "$work/CHANGELOG.md" >&2
	exit 1
}

printf '# Changelog\n\nWhat changed.\n' >"$work/CHANGELOG.md"
cat >"$work/one.md" <<'EOF'
First release.

## What's new

- a thing

```sh
# a shell comment
```
EOF
printf 'Second release.\n\n## Fixes\n\n- another thing\n' >"$work/two.md"

"$root/scripts/changelog.sh" 1.0.0 2026-10-21 "$work/one.md" "$work/CHANGELOG.md" >/dev/null
grep -q '^## \[1.0.0\] - 2026-10-21$' "$work/CHANGELOG.md" || bad "the first section was not added"
grep -q "^### What's new$" "$work/CHANGELOG.md" || bad "the notes' headings were not nested under the release"
grep -q '^# a shell comment$' "$work/CHANGELOG.md" || bad "a line inside a code block was changed"
grep -q '^\[1.0.0\]: https://github.com/osie/coral-paas/releases/tag/v1.0.0$' "$work/CHANGELOG.md" || bad "the first release was not linked"
echo "PASS: adds a release to an empty changelog, nesting its headings"

"$root/scripts/changelog.sh" 1.1.0 2026-10-28 "$work/two.md" "$work/CHANGELOG.md" >/dev/null
[ "$(grep -n '^## \[' "$work/CHANGELOG.md" | cut -d: -f2- | tr '\n' ' ')" = "## [1.1.0] - 2026-10-28 ## [1.0.0] - 2026-10-21 " ] || bad "the newer release is not first"
[ "$(grep '^\[[0-9]' "$work/CHANGELOG.md" | cut -d']' -f1 | tr '\n' ' ')" = "[1.1.0 [1.0.0 " ] || bad "the newer link is not first"
echo "PASS: puts a newer release and its link first"

cp "$work/CHANGELOG.md" "$work/before"
"$root/scripts/changelog.sh" 1.1.0 2026-10-29 "$work/two.md" "$work/CHANGELOG.md" >/dev/null
cmp -s "$work/before" "$work/CHANGELOG.md" || bad "adding a release twice changed the changelog"
echo "PASS: adding a release again changes nothing"

if "$root/scripts/changelog.sh" 1.2.0 2026-11-01 "$work/missing.md" "$work/CHANGELOG.md" 2>/dev/null; then
	bad "accepted missing release notes"
fi
cmp -s "$work/before" "$work/CHANGELOG.md" || bad "missing notes changed the changelog"
echo "PASS: refuses missing release notes"
