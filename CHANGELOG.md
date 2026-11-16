# Changelog

## [Unreleased]

### Fixed

- Fixed the CI workflow grep checks to match the `SOURCE_REF` variable the launchers actually use, instead of a literal `/dev/` path segment that never appears in the scripts.

### Added

- Added `androidCurlScripts.sh` as a numbered Android and Termux launcher.
- Added `linuxCurlScripts.sh` as a numbered Linux and network launcher.
- Added direct command examples and a link to the full implementation branch.
