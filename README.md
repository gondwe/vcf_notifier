# VcfNotifier

A flexible notification library for Elixir applications supporting multiple notification channels with robust background processing using Oban queues.

## 🚀 Features

### Email Notifications
- **Multiple Providers**: SMTP, SendGrid, Mailgun, Postmark, Amazon SES
- **Rich Content**: HTML emails, plain text, attachments
- **Advanced Features**: CC/BCC, custom headers, reply-to
- **Background Processing**: Reliable delivery using Oban workers
- **Scheduled Delivery**: Send emails at specific times or after delays
- **Bulk Sending**: Efficient bulk email operations
- **Error Handling**: Automatic retries and comprehensive logging

### Background Job Processing
- **Oban Integration**: Reliable background job processing
- **Queue Management**: Separate queues for different notification types
- **Retry Logic**: Configurable retry attempts with exponential backoff
- **Job Monitoring**: Built-in statistics and monitoring capabilities
- **Dead Letter Queue**: Handle permanently failed jobs

### Multi-Channel Support
- **Email**: Full-featured email notifications
- **SMS**: SMS notifications (ready for provider integration)
- **Push Notifications**: Push notification support (ready for provider integration)
- **Webhooks**: Webhook notifications (ready for provider integration)

## 📦 Installation

Add `vcf_notifier` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vcf_notifier, "~> 0.1.0"}
  ]
end
```

## ⚡ Quick Start

### 1. Configuration

Add to your `config/config.exs`:

```elixir
# Database repo (required for Oban)
config :vcf_notifier, 
  repo: MyApp.Repo

# Oban configuration
config :vcf_notifier, Oban,
  repo: MyApp.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [emails: 10, default: 5]

# Email provider
config :vcf_notifier,
  email_provider: :smtp,
  default_from_email: "noreply@myapp.com"

config :vcf_notifier, :email_providers,
  smtp: %{
    host: "smtp.gmail.com",
    port: 587,
    username: "your-email@gmail.com",
    password: "your-app-password",
    ssl: false,
    tls: :if_available,
    auth: :always
  }
```

### 2. Add to Supervision Tree

```elixir
# In your application.ex
def start(_type, _args) do
  children = [
    MyApp.Repo,
    MyAppWeb.Endpoint,
    VcfNotifier.Application  # Add this line
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

### 3. Send Notifications

```elixir
# Simple email
Notification.send(%{
  type: :email,
  to: "user@example.com",
  subject: "Welcome!",
  body: "Welcome to our service!"
})

# Background email
Notification.send_async(%{
  type: :email,
  to: "user@example.com",
  subject: "Newsletter",
  body: "Your weekly newsletter",
  metadata: %{
    html_body: "<h1>Newsletter</h1><p>Content here...</p>"
  }
})

# Scheduled email (1 hour from now)
Notification.send_in(%{
  type: :email,
  to: "user@example.com",
  subject: "Reminder",
  body: "Don't forget your appointment!"
}, 3600)

# Bulk emails
recipients = ["user1@example.com", "user2@example.com"]
email_data = %{
  subject: "Announcement",
  body: "Important announcement for everyone"
}
Notification.send_bulk_email(recipients, email_data)

# Alternative: You can also use VcfNotifier directly
VcfNotifier.send(%{type: :email, to: "user@example.com", subject: "Test", body: "Hello"})
```

## 📧 Email Providers

### SMTP
```elixir
config :vcf_notifier, :email_providers,
  smtp: %{
    host: "smtp.gmail.com",
    port: 587,
    username: "your-email@gmail.com",
    password: "your-app-password",
    ssl: false,
    tls: :if_available,
    auth: :always
  }
```

### SendGrid
```elixir
config :vcf_notifier,
  email_provider: :sendgrid

config :vcf_notifier, :email_providers,
  sendgrid: %{
    api_key: "your-sendgrid-api-key"
  }
```

### Mailgun
```elixir
config :vcf_notifier,
  email_provider: :mailgun

config :vcf_notifier, :email_providers,
  mailgun: %{
    api_key: "your-mailgun-api-key",
    domain: "your-domain.com"
  }
```

## 🔧 Advanced Features

### HTML Emails with Attachments
```elixir
Notification.send_async(%{
  type: :email,
  to: "user@example.com",
  subject: "Invoice",
  body: "Please find your invoice attached.",
  metadata: %{
    html_body: "<h1>Invoice</h1><p>Thank you for your business!</p>",
    cc: ["accounting@company.com"],
    attachments: [
      %{
        filename: "invoice.pdf",
        content_type: "application/pdf",
        data: File.read!("invoice.pdf")
      }
    ]
  }
})
```

### Priority and Custom Retry Settings
```elixir
Notification.send_async(%{
  type: :email,
  to: "urgent@example.com",
  subject: "Urgent Notification",
  body: "This is urgent!"
}, priority: 1, max_attempts: 5)
```

### Monitoring and Statistics
```elixir
# Get email delivery statistics
stats = VcfNotifier.Email.Service.get_stats()
# => %{available: 0, scheduled: 2, executing: 0, completed: 15, ...}
```

## 🧪 Testing

For testing, configure a test adapter:

```elixir
# In config/test.exs
config :vcf_notifier,
  email_provider: :test

config :vcf_notifier, Oban,
  testing: :manual,
  queues: false

config :swoosh, :api_client, false
```

## 📚 Documentation

- [Email Guide](EMAIL_GUIDE.md) - Comprehensive email documentation
- [Configuration Template](config/config_template.exs) - Example configuration
- [Example Scripts](examples/) - Working examples

## 🏗️ Architecture

### Core Components
- **VcfNotifier**: Main API module
- **Notification**: Notification data structure
- **Email.Service**: High-level email operations
- **Email.Provider**: Email provider abstraction
- **Workers.EmailWorker**: Oban worker for background processing

### Dependencies
- **Swoosh**: Email delivery abstraction
- **Oban**: Background job processing
- **Finch**: HTTP client for email services
- **Ecto**: Database operations (for Oban)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`mix test`)
4. Commit your changes (`git commit -am 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Roadmap

- [ ] Additional email providers (Resend, Brevo)
- [ ] SMS provider integrations (Twilio, AWS SNS)
- [ ] Push notification providers (FCM, APNS)
- [ ] Webhook integrations
- [ ] Email template system
- [ ] Advanced scheduling features
- [ ] Delivery analytics dashboard

## 💬 Support

- 📧 Email: support@valuechain.factory
- 🐛 Issues: [GitHub Issues](https://github.com/gondwe/vcf_notifier/issues)
- 📖 Docs: [Documentation](https://hexdocs.pm/vcf_notifier)
