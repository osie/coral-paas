SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:
.DEFAULT_GOAL := help

ARTIFACT ?= ghcr.io/osie/coralctl
ORAS_FLAGS ?=
VERIFY ?= 1
SIGNER := https://github.com/osie/coral/.github/workflows/release.yml@refs/tags
ISSUER := https://token.actions.githubusercontent.com
PLATFORMS := linux-amd64 linux-arm64 darwin-amd64 darwin-arm64
TAG ?=
VERSION = $(patsubst v%,%,$(TAG))

.PHONY: help ci lint test tag pull formula changelog release-prep check-pins completions package sums \
	yamllint shellcheck codespell actionlint ruby test-install test-changelog clean

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

ci: lint test ## Everything CI runs

lint: yamllint shellcheck codespell actionlint ruby ## Every linter

test: test-install test-changelog ## Every test

tag:
	@[[ "$(TAG)" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$$ ]] || { echo "TAG must be v<major>.<minor>.<patch>, not '$(TAG)'" >&2; exit 1; }

pull: tag ## Pull coralctl $(TAG) into dist/, checking its signature and every checksum
	@rm -rf dist
	mkdir -p dist
	digest=$$(oras resolve $(ORAS_FLAGS) "$(ARTIFACT):$(VERSION)")
	if [ "$(VERIFY)" = 1 ]; then
		cosign verify "$(ARTIFACT)@$$digest" --certificate-identity "$(SIGNER)/$(TAG)" --certificate-oidc-issuer "$(ISSUER)" >/dev/null
		echo "$(ARTIFACT)@$$digest is signed by osie/coral's release workflow at $(TAG)"
	fi
	oras pull $(ORAS_FLAGS) "$(ARTIFACT)@$$digest" -o dist >/dev/null
	cd dist
	for p in $(PLATFORMS); do sha256sum -c "coralctl-$$p.sha256"; chmod 0755 "coralctl-$$p"; done
	built=$$(./coralctl-linux-amd64 version)
	[[ $$built == "coralctl $(TAG) "* ]] || { echo "dist/coralctl-linux-amd64 is not $(TAG): $${built%%$$'\n'*}" >&2; exit 1; }

formula: ## Write Formula/coralctl.rb and examples/hub.yaml from the coralctl in dist/
	@scripts/formula.sh "$(VERSION)" dist > Formula/coralctl.rb
	cp dist/hub.example.yaml examples/hub.yaml
	echo "wrote Formula/coralctl.rb and examples/hub.yaml for $(TAG)"

changelog: tag ## Add $(TAG)'s section to CHANGELOG.md from the release notes in dist/
	@scripts/changelog.sh "$(VERSION)" "$$(date -u +%Y-%m-%d)" dist/RELEASE_NOTES.md

release-prep: pull formula changelog ## Pull $(TAG), check its signature, and write the formula, example spec and changelog section that pin it

check-pins: tag ## Formula/coralctl.rb, examples/hub.yaml and CHANGELOG.md name the coralctl in dist/
	@diff -u Formula/coralctl.rb <(scripts/formula.sh "$(VERSION)" dist) || { echo "Formula/coralctl.rb does not pin $(TAG): run make release-prep TAG=$(TAG)" >&2; exit 1; }
	cmp -s examples/hub.yaml dist/hub.example.yaml || { echo "examples/hub.yaml is not $(TAG)'s: run make release-prep TAG=$(TAG)" >&2; exit 1; }
	grep -q "^## \[$(VERSION)\]" CHANGELOG.md || { echo "CHANGELOG.md has no section for $(VERSION)" >&2; exit 1; }
	echo "Formula/coralctl.rb, examples/hub.yaml and CHANGELOG.md pin $(TAG)"

completions: ## Write the shell completions into dist/completions
	@mkdir -p dist/completions
	for shell in bash fish; do dist/coralctl-linux-amd64 completion "$$shell" > "dist/completions/coralctl.$$shell"; done
	dist/coralctl-linux-amd64 completion zsh > dist/completions/_coralctl

package: tag completions ## Build the .deb and .rpm packages for Linux amd64 and arm64 into dist/
	@mkdir -p dist/package
	for arch in amd64 arm64; do
		cp "dist/coralctl-linux-$$arch" dist/package/coralctl
		for packager in deb rpm; do
			ARCH=$$arch VERSION=$(VERSION) nfpm package --config packaging/nfpm.yaml --packager "$$packager" --target dist/
		done
	done
	rm -rf dist/package

sums: ## Write dist/SHA256SUMS over every file a release publishes
	@cp install.sh dist/install.sh
	cd dist
	sha256sum coralctl-linux-amd64 coralctl-linux-arm64 coralctl-darwin-amd64 coralctl-darwin-arm64 \
		*.deb *.rpm install.sh THIRD_PARTY_NOTICES.txt > SHA256SUMS
	cat SHA256SUMS

yamllint:
	@yamllint -s .

shellcheck:
	@shellcheck install.sh scripts/*.sh

codespell:
	@codespell

actionlint:
	@actionlint

ruby:
	@shopt -s nullglob
	for f in Formula/*.rb; do ruby -c "$$f" >/dev/null; echo "$$f parses"; done

test-install: ## install.sh installs a release, checks its checksum and refuses a bad one
	@scripts/test-install.sh

test-changelog: ## A release's notes become its changelog section, once, newest first
	@scripts/test-changelog.sh

clean: ## Remove dist/
	@rm -rf dist
