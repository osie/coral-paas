#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

case $(uname -s) in
Linux) os=linux ;;
Darwin) os=darwin ;;
*) echo "test-install.sh: runs on Linux and macOS" >&2 && exit 1 ;;
esac
case $(uname -m) in
x86_64 | amd64) arch=amd64 ;;
aarch64 | arm64) arch=arm64 ;;
*) echo "test-install.sh: runs on amd64 and arm64" >&2 && exit 1 ;;
esac

if command -v sha256sum >/dev/null 2>&1; then
	sum() { sha256sum "$@"; }
else
	sum() { shasum -a 256 "$@"; }
fi

release=$work/release
mkdir -p "$release" "$work/signed" "$work/forged"
printf '#!/bin/sh\necho "coralctl v9.9.9 (commit test)"\n' >"$release/coralctl-$os-$arch"
echo '{}' >"$release/SHA256SUMS.sigstore.json"
(cd "$release" && sum "coralctl-$os-$arch" >SHA256SUMS)
printf '#!/bin/sh\nexit 0\n' >"$work/signed/cosign"
printf '#!/bin/sh\necho "error: none of the expected identities matched" >&2\nexit 1\n' >"$work/forged/cosign"
chmod 0755 "$release/coralctl-$os-$arch" "$work/signed/cosign" "$work/forged/cosign"

ok() { echo "PASS: $*"; }
bad() {
	echo "FAIL: $*" >&2
	exit 1
}

run() {
	path=$1
	shift
	CORALCTL_DOWNLOAD_URL=file://$release PATH=$path sh "$root/install.sh" "$@" >"$work/out" 2>&1
}

run "$work/signed:$PATH" --version v9.9.9 --dir "$work/bin" || bad "a signed release with a matching checksum did not install: $(cat "$work/out")"
grep -q 'signed by osie/coral-paas' "$work/out" || bad "the signature was not checked: $(cat "$work/out")"
[ "$("$work/bin/coralctl" version)" = "coralctl v9.9.9 (commit test)" ] || bad "the installed coralctl is not the release's"
ok "installs a signed release with a matching checksum"

if run "$work/forged:$PATH" --version v9.9.9 --dir "$work/forged-bin"; then
	bad "installed a release whose signature does not verify"
fi
grep -q 'does not carry a valid signature' "$work/out" || bad "a bad signature was refused without saying so: $(cat "$work/out")"
[ ! -e "$work/forged-bin/coralctl" ] || bad "left a binary behind after refusing it"
ok "refuses a release whose signature does not verify"

cp "$release/SHA256SUMS" "$work/SHA256SUMS.good"
echo "0000000000000000000000000000000000000000000000000000000000000000  coralctl-$os-$arch" >"$release/SHA256SUMS"
if run "$work/signed:$PATH" --dir "$work/tampered-bin"; then
	bad "installed a binary that does not match SHA256SUMS"
fi
grep -q 'not the 0000' "$work/out" || bad "a checksum mismatch was refused without saying so: $(cat "$work/out")"
[ ! -e "$work/tampered-bin/coralctl" ] || bad "left a binary behind after refusing it"
ok "refuses a binary that does not match SHA256SUMS"
cp "$work/SHA256SUMS.good" "$release/SHA256SUMS"

if run "$work/signed:$PATH" --bogus; then
	bad "accepted an unknown argument"
fi
ok "refuses an unknown argument"

nocosign=/usr/bin:/bin
if ! PATH=$nocosign command -v cosign >/dev/null 2>&1; then
	run "$nocosign" --dir "$work/plain-bin" || bad "did not install without cosign: $(cat "$work/out")"
	grep -q 'checking the checksum only' "$work/out" || bad "did not say the signature went unchecked: $(cat "$work/out")"
	ok "installs on the checksum alone without cosign, and says so"
fi
