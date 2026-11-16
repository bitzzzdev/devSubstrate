# Changelog

## [Unreleased]

### Added

- `DEVSUBSTRATE_REMOTE` switch in `androidCurlScripts.sh` and `linuxCurlScripts.sh`. Set it to `gitlab` to fetch the implementation scripts from `gitlab.com/bitzzdev/devSubstrate/-/raw`; `github` remains the default. Invalid values exit with an error.
- GitLab section in `README.md` with the GitLab raw launcher one-liners and a GitLab link to the full repository, plus `.gitlab-ci.yml` with the same launcher validation the GitHub Action performs.

### Fixed

- Fixed the CI workflow grep checks to match the `SOURCE_REF` variable the launchers actually use, instead of a literal `/dev/` path segment that never appears in the scripts.

### Added

- Added `androidCurlScripts.sh` as a numbered Android and Termux launcher.
- Added `linuxCurlScripts.sh` as a numbered Linux and network launcher.
- Added direct command examples and a link to the full implementation branch.
