# Changelog

What changed for operators in each release of `coralctl` and its install paths.
Tags match Coral releases, and each release publishes the `coralctl` of the
same version.

## [0.9.18] - 2026-10-21

First public release of `coralctl`: the binaries for Linux and macOS on amd64
and arm64, the install script, the Homebrew formula, the `.deb` and `.rpm`
packages, the example hub spec and the guides.

### Added

- `coralctl version --check` unpacks the `k0sctl` and `helm` the CLI carries and
  runs them, so a binary that cannot run on a machine fails before a hub
  depends on it.
- Each release publishes `THIRD_PARTY_NOTICES.txt`, the licenses of the
  open-source software inside `coralctl`. The packages install it under
  `/usr/share/doc/coralctl`.
- `SHA256SUMS` over every file a release publishes, signed by this repository's
  release workflow, which publishes only binaries Coral's own release signed at
  the same tag.

### Upgrade notes

- Nothing on a hub changes with this release's `coralctl`. Run
  `coralctl hub upgrade --chart 0.9.18` to move a hub to Coral 0.9.18; it
  restarts only the hub's own controllers.

[0.9.18]: https://github.com/osie/coral-paas/releases/tag/v0.9.18
