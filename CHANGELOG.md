# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Breaking Changes

  - The `RFacter::Util::Collection` class now requires a `RFacter::Node`
    instance to be passed to its constructor. Instance methods like
    `value` and `to_hash` no longer accept a node argument. This change
    means that a separate collection must be created for each node, but
    simplifies per-node caching behavior.

### Added

  - Timing of fact resolutions has been re-added. This can be enabled by passing
    the `--profile` flag to the `rfacter` CLI.
  - A suite of Acceptance tests powered by beaker-rspec.
  - The `/etc/os-release` file is now parsed when determining `os.name` for Linux.
  - The `RFacter::Factset` class which is capable of coordinating the
    concurrent resolution of facts across a number of nodes. This is the
    preferred interface for retrieving fact data.

### Removed

  - The `ldapname` option has been retired from RFacter::Util::Fact.


## [0.0.1] - 2017-05-10
### Added

  - A formal DSL for custom facts based on the [Facter 3 Ruby API][facter-3-api].
  - Support for resolving facts on remote nodes over transports such as SSH
    and WinRM.
  - Partial implementation of the `os` and `networking` facts from Facter 3.

### Removed

  - Loading of facts from `ENV` variables and the Ruby `LOAD_PATH`.
  - Support for external facts.
  - All core facts from Ruby 2.4. These will be re-added in later releases
    on a case-by-case basis.

[facter-3-api]: https://github.com/puppetlabs/facter/blob/master/Extensibility.md#custom-facts-compatibility

[Unreleased]: https://github.com/Sharpie/rfacter/compare/0.0.1...HEAD
[0.0.1]: https://github.com/Sharpie/rfacter/compare/7ceb3e9...0.0.1
