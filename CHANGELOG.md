# Changelog

All notable changes to this project will be documented in this file.

## [0.1.1] - 2025-08-21

### Added
- Enhanced email system with `VcfNotifier.Email.FlexibleService` for simplified app-controlled email building
- `VcfNotifier.Email.ContextWorker` for advanced context-based email processing  
- `VcfNotifier.Email.Generator` behaviour for structured email builders
- Complete notification behaviour pattern with `send/1`, `send_async/2`, `send_at/3`, `send_in/3`
- Comprehensive documentation including usage examples and design philosophy
- Example mailer implementation
- Enhanced error handling and logging

### Improved
- Refactored core architecture to use handler module pattern
- Better separation between email building and delivery
- More flexible configuration options
- Comprehensive test coverage (31 tests passing)

### Documentation
- Added `USAGE_EXAMPLES.md` with real-world examples
- Added `DESIGN_PHILOSOPHY.md` explaining architectural decisions  
- Added `ADVANCED_EMAIL_GUIDE.md` for complex use cases
- Improved README with quick start guide

## [0.1.0] - 2025-08-21

### Added
- Initial release with basic email notification support
- Oban integration for background processing
- Multiple email provider support (SMTP, SendGrid, Mailgun)
- Basic notification structures and workflows
- Support for email, SMS, push, and webhook notification types
- Synchronous and asynchronous sending
- Notification building and validation