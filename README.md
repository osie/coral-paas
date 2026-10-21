<p align="center">
  <img alt="OSIE" src=".github/assets/osie-logo-light.svg#gh-light-mode-only" width="180">
  <img alt="OSIE" src=".github/assets/osie-logo-dark.svg#gh-dark-mode-only" width="180">
</p>

<h1 align="center">Coral</h1>

<p align="center">
  <strong>Managed databases and Kubernetes for OpenStack</strong><br>
  coralctl, the operator CLI: releases, packages and install paths
</p>

<p align="center">
  <a href="https://github.com/osie/coral-paas/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/osie/coral-paas/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/osie/coral-paas/releases"><img alt="Release" src="https://img.shields.io/github/v/release/osie/coral-paas?sort=semver&color=4F52C9"></a>
  <a href="LICENSE"><img alt="License: Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-4F52C9"></a>
</p>

<p align="center">
  <a href="#install"><strong>Install</strong></a>
  &nbsp;·&nbsp;
  <a href="#quick-start">Quick start</a>
  &nbsp;·&nbsp;
  <a href="#supported-platforms">Supported platforms</a>
  &nbsp;·&nbsp;
  <a href="#verifying-a-download">Verifying a download</a>
  &nbsp;·&nbsp;
  <a href="CHANGELOG.md">Changelog</a>
</p>

<br>

## About Coral

Coral runs managed databases and managed Kubernetes clusters for the projects
of an OpenStack cloud, developed by [OSIE](https://osie.io). The cloud's
operator runs one **service hub** per region, in a project of the cloud's own.
The hub builds and runs the platform clusters that host what projects order,
and serves the API a portal orders through.

Projects order a database or a cluster, size it, back it up and restore it.
The operator declares what the region offers: the engines and their versions,
the instance types, the storage, the backup repositories and the quotas.

`coralctl` is the operator's CLI. It builds a hub on an existing OpenStack
project from one spec file, and runs it for its whole life: scaling, upgrades,
backups, restores, health and support bundles. This repository publishes it.

## Capabilities

<table>
<tr>
<td width="50%" valign="top">

**Managed databases**<br>
PostgreSQL, MySQL, MariaDB, MongoDB, Valkey, RabbitMQ, ClickHouse and
OpenSearch, each run by an established Kubernetes operator, with users,
credentials, scaling and version upgrades through the API.

</td>
<td width="50%" valign="top">

**Managed Kubernetes**<br>
Tenant clusters whose control planes the platform hosts, with node pools in the
project's own network, a choice of operating system per pool, autoscaling and
volume snapshots.

</td>
</tr>
<tr>
<td valign="top">

**Backups and restores**<br>
Scheduled backups to S3-compatible repositories the operator lists, point-in-time
restores where the engine supports them, and restores as new databases.

</td>
<td valign="top">

**Private endpoints**<br>
A database reachable from inside a project's own network, beside or instead of
a public address, with certificates for every name it publishes.

</td>
</tr>
<tr>
<td valign="top">

**One spec, one command**<br>
`coralctl hub create -f hub.yaml` builds the network, the machines, Kubernetes
and the platform, and is re-runnable. It keeps no state of its own: every
command asks the cloud.

</td>
<td valign="top">

**Monitoring and support**<br>
Prometheus, Alertmanager and Grafana across the hub and every platform cluster,
`coralctl health` for what is wrong right now, and a redacted support bundle to
send us.

</td>
</tr>
</table>

## Supported platforms

`coralctl` is one file, with the `k0sctl` and `helm` it runs embedded inside it.

| Platform | File | Install paths | Verified on every release |
|---|---|---|---|
| **Linux x86-64** | `coralctl-linux-amd64` | `install.sh`, Homebrew, `.deb`, `.rpm` | Ubuntu 24.04, Debian 13, Fedora 44, Rocky Linux 9 |
| **Linux arm64** | `coralctl-linux-arm64` | `install.sh`, `.deb`, `.rpm` | Ubuntu 24.04, Debian 13, Rocky Linux 9 |
| **macOS Apple silicon** | `coralctl-darwin-arm64` | `install.sh`, Homebrew | macOS 15 |
| **macOS Intel** | `coralctl-darwin-amd64` | `install.sh`, Homebrew | macOS 15 |
| **Windows** | none | run the Linux file inside WSL2 | not verified |

The `.deb` and `.rpm` packages carry no distribution or glibc dependency: the
binary is statically linked.

## Install

<details open>
<summary><strong>Install script</strong> (Linux and macOS)</summary>

```sh
curl -sSfL https://github.com/osie/coral-paas/releases/latest/download/install.sh | sh
```

It picks the file for the machine, checks it against the release's
`SHA256SUMS`, checks `SHA256SUMS` against its signature when `cosign` is
installed, and installs `coralctl` into `/usr/local/bin`. Pass
`--version v0.9.18` for a given release or `--dir <path>` for another
directory: `curl … | sh -s -- --version v0.9.18`. A region without access to
GitHub can mirror one release's files and point `CORALCTL_DOWNLOAD_URL` at them.

</details>

<details>
<summary><strong>Homebrew</strong> (macOS and Linux)</summary>

```sh
brew tap osie/coral-paas https://github.com/osie/coral-paas
brew install osie/coral-paas/coralctl
```

`brew upgrade coralctl` moves to a new release. Shell completions are installed
with it.

</details>

<details>
<summary><strong>Debian and Ubuntu</strong></summary>

```sh
V=0.9.18; ARCH=$(dpkg --print-architecture)
curl -sSfLO "https://github.com/osie/coral-paas/releases/download/v$V/coralctl_${V}_${ARCH}.deb"
sudo apt-get install "./coralctl_${V}_${ARCH}.deb"
```

</details>

<details>
<summary><strong>RHEL, Rocky Linux, AlmaLinux and Fedora</strong></summary>

```sh
V=0.9.18; ARCH=$(uname -m)
sudo dnf install "https://github.com/osie/coral-paas/releases/download/v$V/coralctl-$V-1.$ARCH.rpm"
```

</details>

<details>
<summary><strong>By hand</strong></summary>

```sh
V=v0.9.18; FILE=coralctl-linux-amd64          # or -linux-arm64, -darwin-amd64, -darwin-arm64
curl -sSfLO "https://github.com/osie/coral-paas/releases/download/$V/$FILE"
curl -sSfL  "https://github.com/osie/coral-paas/releases/download/$V/SHA256SUMS" | grep " $FILE\$" | sha256sum -c -
sudo install -m 0755 "$FILE" /usr/local/bin/coralctl
```

On macOS, use `shasum -a 256 -c -` in place of `sha256sum -c -`. A file
downloaded with a browser rather than `curl` is quarantined by macOS;
`xattr -d com.apple.quarantine coralctl` releases it.

</details>

Then check that it runs, and that the tools it carries run on this machine:

```sh
coralctl version --check
```

## Verifying a download

Every release publishes `SHA256SUMS` over its files, and
`SHA256SUMS.sigstore.json`, a keyless [Sigstore](https://www.sigstore.dev/)
signature made by this repository's release workflow at the release's tag. With
[cosign](https://github.com/sigstore/cosign) 2.4 or newer:

```sh
V=v0.9.18
cosign verify-blob SHA256SUMS --bundle SHA256SUMS.sigstore.json \
  --certificate-identity "https://github.com/osie/coral-paas/.github/workflows/release.yml@refs/tags/$V" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
grep " coralctl-linux-amd64\$" SHA256SUMS | sha256sum -c -
```

The release workflow publishes only binaries that Coral's own release signed at
the same tag, and the [container images](#container-images) are signed the same
way. The `.deb` and `.rpm` packages are not GPG-signed; check them through
`SHA256SUMS`.

## Quick start

A hub is declared in one spec file. [`examples/hub.yaml`](examples/hub.yaml)
documents every field, with the value each one defaults to:

```sh
mkdir -p hubs/region-one && cd hubs/region-one
curl -sSfLo hub.yaml https://raw.githubusercontent.com/osie/coral-paas/v0.9.18/examples/hub.yaml
$EDITOR hub.yaml                 # the cloud, the region, the network, the machines
coralctl use hub.yaml            # the commands below then need no -f
coralctl hub create              # builds the network, machines, Kubernetes and the platform
coralctl hub status
coralctl health
```

`create` converges the cloud onto the spec and is safe to run again; commit the
spec and re-apply it on change. `coralctl --help` lists every command, and each
one's `--help` says what it does and what it changes.

## Requirements

| Requirement | Details |
|---|---|
| **The machine coralctl runs on** | Linux or macOS, amd64 or arm64; `kubectl` only for `coralctl kubectl` and `coralctl hub balancer` |
| **OpenStack** | Keystone v3, Nova, Neutron, Cinder and Octavia; a hub whose machines sit on the external network can use MetalLB in place of Octavia for its own addresses |
| **Credential** | a `clouds.yaml` entry for the hub's project, ideally an application credential with `member` on it; identity federation needs more, as `identity.federationObjects` in the example spec explains |
| **Network** | the cloud's APIs from the operator's machine, and the hub's addresses from one of the spec's `adminCIDRs` |
| **Egress from the hub** | `ghcr.io` for Coral's images and chart, and the public registries and release sites of the components it installs |

## Versions and upgrades

A tag here names the Coral release of the same version. Use the `coralctl` of
the release a hub runs, or of the one it is moving to: an older `coralctl`
refuses to apply its schemas over a newer release's, and names the version to
use. To upgrade a hub, install the new `coralctl` first, then:

```sh
coralctl hub upgrade --chart 0.9.18
```

The [changelog](CHANGELOG.md) says what each release changes, and what an
upgrade restarts.

## Container images

| Image | Runs |
|---|---|
| `ghcr.io/osie/coral` | the hub's controllers and its API |
| `ghcr.io/osie/coral-network-agent` | the private endpoints' network agent |
| `ghcr.io/osie/coral-snapshot-uploader` | control-plane snapshots, beside each hosted control plane |
| `ghcr.io/osie/coral-backup-signer` | the object-store signer beside a database's backup tool |
| `oci://ghcr.io/osie/charts/coral` | the Helm chart `coralctl` installs on the hub |

`coralctl` and the images are built from Coral's source, which is not part of
this repository, and they are not covered by this repository's license.
`THIRD_PARTY_NOTICES.txt` in each release lists the open-source software inside
`coralctl` and its licenses.

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md)
first, and report security issues privately as [SECURITY.md](SECURITY.md)
describes.

## License

The contents of this repository are licensed under the
[Apache License, Version 2.0](LICENSE).

<br>

<p align="center">
  <sub>Coral is developed by <a href="https://osie.io">OSIE</a>.</sub>
</p>
