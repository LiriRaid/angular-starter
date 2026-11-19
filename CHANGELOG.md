# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project intends to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once released.

## [Unreleased]

### Added

- Initial repository with README, MIT license and community files.
- CLI core (`@as-starter/cli`, binaries `as-starter` and `as`): `new` (interactive wizard,
  flags, `--defaults`, `--config`, `--dry-run`), `list`, `info`, `doctor`, `version` and help.
  `new` runs the official `ng new` (Angular CLI 22.3.0) and writes `angular-starter.config.json`.
- Capability registry: options that cannot be generated yet are hidden from the wizard and help and
  rejected with a clear message.
- ADR-0001 documenting the CLI architecture and toolchain.
