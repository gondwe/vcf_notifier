# VcfNotifier Release Notes

## v0.1.1 - Ultra-Lightweight Release

### What's New
- **Provider Agnostic**: Removed all email provider dependencies (Swoosh, Finch)
- **Ultra-Simple API**: Single `send/1` function for queuing emails
- **Clean Integration**: `use VcfNotifier.Mailer` pattern for seamless app integration
- **Minimal Dependencies**: Only requires Oban, Ecto, and database adapter

### Breaking Changes
- Removed all provider-specific code (Swoosh integrations)
- Simplified from complex notification system to email-only queuing
- Applications now implement their own `deliver/1` callback

### Usage
```elixir
defmodule MyApp.Mailer do
  use VcfNotifier.Mailer

  def deliver(%VcfNotifier.Email{} = email) do
    # Your email service integration here
    {:ok, result}
  end
end

# Send emails
email = %VcfNotifier.Email{to: "user@example.com", from: "app@example.com", subject: "Hello", text_body: "World"}
MyApp.Mailer.send(email)
```

### Dependencies
- `oban ~> 2.15` - Background processing
- `ecto_sql ~> 3.10` - Database for Oban
- `postgrex ~> 0.17` - PostgreSQL adapter (or your DB choice)
- `jason ~> 1.4` - JSON serialization

### File Count
- **4 core files** in `lib/`
- **3 test files** 
- **Total: ~200 lines of code**

### Migration from v0.1.0
Replace provider configurations with a simple delivery function:
```elixir
# Before: Complex provider config
# After: Simple delivery callback
config :vcf_notifier, delivery_function: &MyApp.EmailService.deliver/1
```
