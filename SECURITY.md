# Security

## Reporting a vulnerability

Please do not open a public issue for a security problem. Report it privately
through GitHub: open the repository's **Security** tab and choose **Report a
vulnerability**, or go to <https://github.com/osie/coral-paas/security/advisories/new>.

Include what is affected (`coralctl`, a Coral component, the install script or a
package), the versions, and how to reproduce it. We aim to acknowledge reports
within three working days and keep you informed until a fix is released. We
credit reporters in the advisory unless you ask us not to.

Vulnerabilities in Coral itself, rather than in this repository, are welcome
through the same channel; we route them to the right place.

## Supported versions

Fixes are made in the latest release. Upgrade to it to receive them.

## What this repository is responsible for

`coralctl` runs as the operator, with a credential for the cloud project a hub
lives in, and it executes the k0sctl and helm it carries. So these are in
scope:

- a way to install a `coralctl` that is not the one Coral's release built: the
  install script, the formula or a package accepting a binary whose checksum or
  signature does not match;
- a release here that does not refuse binaries Coral's release workflow did not
  sign at the same tag;
- a file installed writable by other users, or a secret written to a log, a
  package or a world-readable file.

## Verifying what you downloaded

Every release publishes `SHA256SUMS` over its files and
`SHA256SUMS.sigstore.json`, a keyless signature by this repository's release
workflow. The README's [Verifying a download](README.md#verifying-a-download)
gives the commands.
