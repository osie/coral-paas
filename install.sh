#!/bin/sh
set -eu

repo=osie/coral-paas
version=${CORALCTL_VERSION:-latest}
dir=${CORALCTL_INSTALL_DIR:-/usr/local/bin}
base=${CORALCTL_DOWNLOAD_URL:-}
issuer=https://token.actions.githubusercontent.com

usage() {
	cat <<'EOF'
Install coralctl, the operator CLI for Coral.

  curl -sSfL https://github.com/osie/coral-paas/releases/latest/download/install.sh | sh
  curl -sSfL https://github.com/osie/coral-paas/releases/latest/download/install.sh | sh -s -- --version v0.9.18

Options:
  --version <tag>   the release to install (default: the latest)
  --dir <path>      the directory to install it in (default: /usr/local/bin)

Environment:
  CORALCTL_VERSION        the same as --version
  CORALCTL_INSTALL_DIR    the same as --dir
  CORALCTL_DOWNLOAD_URL   a mirror holding one release's files, used instead of GitHub

The binary is checked against the release's SHA256SUMS, and SHA256SUMS against
its signature when cosign is installed.
EOF
}

fail() {
	echo "install.sh: $*" >&2
	exit 1
}

while [ $# -gt 0 ]; do
	case $1 in
	--version)
		[ $# -ge 2 ] || fail "--version needs a tag"
		version=$2
		shift 2
		;;
	--dir)
		[ $# -ge 2 ] || fail "--dir needs a path"
		dir=$2
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*) fail "unknown argument $1; see --help" ;;
	esac
done

case $(uname -s) in
Linux) os=linux ;;
Darwin) os=darwin ;;
MINGW* | MSYS* | CYGWIN*) fail "coralctl runs on Linux and macOS; on Windows, run this inside WSL2" ;;
*) fail "coralctl runs on Linux and macOS, not $(uname -s)" ;;
esac
case $(uname -m) in
x86_64 | amd64) arch=amd64 ;;
aarch64 | arm64) arch=arm64 ;;
*) fail "coralctl is built for amd64 and arm64, not $(uname -m)" ;;
esac

case $version in
latest | v*) ;;
*) version=v$version ;;
esac
if [ -z "$base" ]; then
	if [ "$version" = latest ]; then
		base=https://github.com/$repo/releases/latest/download
	else
		base=https://github.com/$repo/releases/download/$version
	fi
fi

if command -v curl >/dev/null 2>&1; then
	fetch() { curl -sSfL --retry 3 -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
	fetch() { wget -q -O "$2" "$1"; }
else
	fail "needs curl or wget"
fi
if command -v sha256sum >/dev/null 2>&1; then
	sum() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
	sum() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
	fail "needs sha256sum or shasum to check the download"
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT TERM
file=coralctl-$os-$arch

echo "downloading $file ($version) from $base"
fetch "$base/$file" "$tmp/$file" || fail "could not download $base/$file"
fetch "$base/SHA256SUMS" "$tmp/SHA256SUMS" || fail "could not download $base/SHA256SUMS"

if command -v cosign >/dev/null 2>&1; then
	fetch "$base/SHA256SUMS.sigstore.json" "$tmp/SHA256SUMS.sigstore.json" || fail "could not download $base/SHA256SUMS.sigstore.json"
	if [ "$version" = latest ]; then
		set -- --certificate-identity-regexp "^https://github\.com/$repo/\.github/workflows/release\.yml@refs/tags/v"
	else
		set -- --certificate-identity "https://github.com/$repo/.github/workflows/release.yml@refs/tags/$version"
	fi
	cosign verify-blob "$tmp/SHA256SUMS" --bundle "$tmp/SHA256SUMS.sigstore.json" "$@" \
		--certificate-oidc-issuer "$issuer" >"$tmp/cosign.log" 2>&1 ||
		fail "SHA256SUMS does not carry a valid signature from $repo's release workflow: $(tail -n 1 "$tmp/cosign.log")"
	echo "SHA256SUMS is signed by $repo's release workflow"
else
	echo "cosign is not installed: checking the checksum only"
fi

want=$(awk -v f="$file" '$2 == f || $2 == "*" f { print $1 }' "$tmp/SHA256SUMS")
[ -n "$want" ] || fail "SHA256SUMS lists no $file"
got=$(sum "$tmp/$file")
[ "$got" = "$want" ] || fail "$file hashes to $got, not the $want SHA256SUMS lists"
echo "$file matches SHA256SUMS"

chmod 0755 "$tmp/$file"
if [ -d "$dir" ] && [ -w "$dir" ]; then
	mv "$tmp/$file" "$dir/coralctl"
elif mkdir -p "$dir" 2>/dev/null && [ -w "$dir" ]; then
	mv "$tmp/$file" "$dir/coralctl"
elif command -v sudo >/dev/null 2>&1; then
	echo "installing into $dir with sudo"
	sudo mkdir -p "$dir"
	sudo mv "$tmp/$file" "$dir/coralctl"
else
	fail "$dir is not writable; pass --dir with one that is"
fi
echo "installed $dir/coralctl"
"$dir/coralctl" version | head -n 1
