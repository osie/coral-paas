#!/bin/sh
set -eu

version=${1:?usage: formula.sh <version> <directory holding coralctl-<os>-<arch>.sha256>}
dist=${2:?usage: formula.sh <version> <directory holding coralctl-<os>-<arch>.sha256>}
url=https://github.com/osie/coral-paas/releases/download/v$version

sum() {
	[ -s "$dist/coralctl-$1.sha256" ] || {
		echo "formula.sh: $dist/coralctl-$1.sha256 is missing" >&2
		exit 1
	}
	cut -d' ' -f1 "$dist/coralctl-$1.sha256"
}

darwin_arm64=$(sum darwin-arm64)
darwin_amd64=$(sum darwin-amd64)
linux_arm64=$(sum linux-arm64)
linux_amd64=$(sum linux-amd64)

cat <<EOF
class Coralctl < Formula
  desc "Operator CLI for Coral, managed databases and Kubernetes on OpenStack"
  homepage "https://github.com/osie/coral-paas"
  version "$version"
  license :cannot_represent

  on_macos do
    on_arm do
      url "$url/coralctl-darwin-arm64"
      sha256 "$darwin_arm64"
    end
    on_intel do
      url "$url/coralctl-darwin-amd64"
      sha256 "$darwin_amd64"
    end
  end

  on_linux do
    on_arm do
      url "$url/coralctl-linux-arm64"
      sha256 "$linux_arm64"
    end
    on_intel do
      url "$url/coralctl-linux-amd64"
      sha256 "$linux_amd64"
    end
  end

  def install
    bin.install Dir["coralctl-*"].first => "coralctl"
    generate_completions_from_executable(bin/"coralctl", "completion")
  end

  test do
    assert_match "coralctl v#{version} ", shell_output("#{bin}/coralctl version")
    assert_match "helm", shell_output("#{bin}/coralctl version --check")
  end
end
EOF
