# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An Amazon VPC DHCP option set whose defaults match the Region's default option set: the Amazon DNS server and the Region's domain name.
- Your own domain name, DNS servers, time (NTP) servers, NetBIOS name servers and node type, and IPv6 address lease time, each checked at plan time against the limits AWS sets.
- A new option set is created before the old one is deleted when an option changes, so a VPC association moves to it in place.
- `region`, to create the option set in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic option set and for a VPC that uses Active Directory domain controllers.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-vpc_dhcp_options/releases/tag/v1.0.0
