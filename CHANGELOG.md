# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- Timing of fact resolutions has been re-added. The `rfacter` CLI also accepts
  a `--timing` flag.
- A suite of Acceptance tests powered by beaker-rspec.

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
