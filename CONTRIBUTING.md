# Contributing

Thank you for helping. Bug reports, reports from a platform or distribution we
have not tested, and corrections to the guides are all welcome.

## How this repository is maintained

`coralctl` is built from Coral's source, which is not part of this repository.
Each Coral release publishes its binaries, and this repository's release
workflow turns them into a GitHub release here: it checks that the binaries
were signed by Coral's own release at the same tag, builds the `.deb` and
`.rpm` packages, and signs the checksums. A tag here always names the Coral
release of the same version.

The install script, the Homebrew formula, the packaging and the guides live
here, and pull requests against them are reviewed and merged here as usual.
`examples/hub.yaml` is copied from the Coral release on each tag, so a fix to
it goes to Coral and arrives back with the next release.

## Reporting a bug

Open an issue with the bug template. The most useful things to include:

- how you installed `coralctl`, and on which platform;
- the whole output of `coralctl version --check`;
- the OpenStack release and distribution, if the problem is with a hub;
- what you ran, what happened, and what you expected.

For a problem with a running hub, `coralctl hub support-bundle` writes one
redacted archive of it. Send it to support@osie.io rather than attaching it to
a public issue.

Security issues go through [SECURITY.md](SECURITY.md), never a public issue.

## Making a change

You need `shellcheck`, `yamllint`, `codespell`, `actionlint` and Ruby. Then:

```sh
make lint   # shellcheck, yamllint, codespell, actionlint, the formula parses
make test   # install.sh installs a release and refuses a bad checksum or signature
```

CI runs the same targets, and `make test` on Linux and macOS.

Some things to keep in mind:

- **`install.sh` is POSIX sh.** It runs under dash, busybox and macOS's sh, with
  either `curl` or `wget` and either `sha256sum` or `shasum`.
- **A download is never installed unchecked.** The script refuses a binary that
  does not match `SHA256SUMS`, and checks the signature whenever `cosign` is on
  the machine.
- **No credentials, hostnames or addresses from a real cloud**, in code,
  examples or tests. Use `example.com`, the documentation address ranges and
  obviously fake values.

## Releasing

For maintainers, once Coral has published a release:

```sh
make release-prep TAG=v0.9.18   # pulls it, checks its signature, writes the formula and examples/hub.yaml
$EDITOR CHANGELOG.md            # a section for 0.9.18
git commit -s -am "release v0.9.18" && git tag v0.9.18 && git push origin main v0.9.18
```

The release workflow publishes the release, then installs it with `install.sh`,
Homebrew and the packages on every supported platform.

## Commits and sign-off

Write commit messages that say what changed and why. Sign off each commit to
certify the [Developer Certificate of Origin](https://developercertificate.org/):

```sh
git commit -s
```

By contributing you agree that your contribution is licensed under the
[Apache License, Version 2.0](LICENSE).
