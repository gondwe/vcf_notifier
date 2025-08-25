# Changelog

## [0.2.0] - 2025-08-26

### Added
- Ecto/Postgres Repo (`VcfNotifier.Repo`) and supervision tree
- Optional automatic Oban start when configured
- Config merging in `VcfNotifier.Email.send/2`
- Safe fallback when Oban not started (returns changeset instead of raising)
- Minimal test adapter pattern example

### Changed
- BREAKING: Renamed internal delivery flow; apps now rely on Bamboo adapter directly
- BREAKING: Removed `oban_manual_testing?` flag logic (simpler conditional insertion)
- Simplified Mailer API (`send/2` with config map)

### Removed
- Legacy provider docs and unused Swoosh/Finch references
- Duplicate `VcfNotifier.Application` definition

### Fixed
- Warning about module redefinition
- Potential runtime errors when Oban registry absent

## [0.1.1] - 2025-08-25

### Changed
- **BREAKING**: Removed all provider-specific code (Swoosh integrations)
- **BREAKING**: Simplified to email-only queuing library  
- **BREAKING**: Applications now implement `deliver/1` callback
- Replaced complex notification system with single `send/1` function
- Removed dependencies: `swoosh`, `finch`
- Added `use VcfNotifier.Mailer` integration pattern

### Added
- Ultra-simple API with `MyApp.Mailer.send/1`
- Provider-agnostic email delivery
- Clean integration via behaviour callback

### Removed
- All email provider configurations
- Complex notification routing
- Multiple notification types (SMS, push, webhooks)
- Bulk operations and scheduling (use Oban directly)

## [0.1.0] - 2025-08-21

### Added
- Initial release with notification system
- Email delivery via Swoosh
- Oban integration for background processing
- Initial release with basic email notification support
- Oban integration for background processing
- Multiple email provider support (SMTP, SendGrid, Mailgun)
- Basic notification structures and workflows
- Support for email, SMS, push, and webhook notification types
- Synchronous and asynchronous sending
- Notification building and validation