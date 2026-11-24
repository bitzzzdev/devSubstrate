# Changelog

## [Unreleased]

### Fixed

- Default both launchers to GitLab so a `DEVSUBSTRATE_REMOTE` assignment removed by `sudo` cannot silently switch implementation downloads to GitHub.
- Download implementation scripts to a temporary file, validate with `bash -n`, and execute only after a successful fetch. Report the failed path and source URL.
- Route Linux option `2 wifi` to NetworkManager metered-profile control instead of the QCA9377 radio power-save fix. Keep that hardware-specific fix under the explicit `qca9377` target.

### Added

- Document GitLab-first invocation and correct `sudo env NAME=value bash` placement for overrides.

### Added

- `DEVSUBSTRATE_REMOTE` switch in `androidCurlScripts.sh` and `linuxCurlScripts.sh`. Set it to `gitlab` to fetch the implementation scripts from `gitlab.com/bitzzdev/devSubstrate/-/raw`; `github` remains the default. Invalid values exit with an error.
- Inline GitLab mirror lines in every `README.md` launcher one-liner (fetched from GitLab with `DEVSUBSTRATE_REMOTE=gitlab`), a GitLab link to the full repository, and `.gitlab-ci.yml` with the same launcher validation the GitHub Action performs.

### Fixed

- Fixed the CI workflow grep checks to match the `SOURCE_REF` variable the launchers actually use, instead of a literal `/dev/` path segment that never appears in the scripts.

### Added

- Added `androidCurlScripts.sh` as a numbered Android and Termux launcher.
- Added `linuxCurlScripts.sh` as a numbered Linux and network launcher.
- Added direct command examples and a link to the full implementation branch.
