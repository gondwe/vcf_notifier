# VcfNotifier

A simple Elixir library for reliable email notifications with background processing via Oban.

## Why VcfNotifier?

- **Ultra Simple**: Just one function to queue emails
- **Reliable**: Built on Oban for guaranteed delivery with retries
- **Provider Agnostic**: Works with any email service (Swoosh, Bamboo, custom APIs)
- **Background Processing**: All emails are queued automatically
- **Easy Integration**: Use `VcfNotifier.Mailer` in your app for clean API

## Installation

Add `vcf_notifier` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vcf_notifier, "~> 0.1.1"},
    {:oban, "~> 2.15"},      # Required for background processing
    {:ecto_sql, "~> 3.10"},  # Required for Oban
    {:postgrex, "~> 0.17"}   # Required for Oban (or your DB adapter)
  ]
end
```

## Quick Start

### 1. Create Your Mailer

```elixir
defmodule MyApp.Mailer do
  use VcfNotifier.Mailer

  # Implement delivery using your preferred email service
  def deliver(%VcfNotifier.Email{} = email) do
    # Example with Swoosh
    swoosh_email = 
      Swoosh.Email.new()
      |> Swoosh.Email.to(email.to)
      |> Swoosh.Email.from(email.from)
      |> Swoosh.Email.subject(email.subject)
      |> Swoosh.Email.text_body(email.text_body)
      |> Swoosh.Email.html_body(email.html_body)
    
    MyApp.SwooshMailer.deliver(swoosh_email)
  end
end
```

### 2. Send Emails

```elixir
# Create an email
email = %VcfNotifier.Email{
  to: "user@example.com",
  from: "noreply@myapp.com",
  subject: "Welcome!",
  text_body: "Welcome to our app!",
  html_body: "<h1>Welcome!</h1>"
}

# Queue for delivery
{:ok, job} = MyApp.Mailer.send(email)

# Queue with options (delay, priority, different queue)
{:ok, job} = MyApp.Mailer.send(email, [
  delay: 300,     # Delay 5 minutes
  priority: 1,    # Higher priority
  queue: :urgent  # Use different queue
])
```
email = %VcfNotifier.Email{
  to: ["user@example.com"],
  from: "welcome@myapp.com",
  subject: "Welcome to MyApp!",
  html_body: "<h1>Welcome!</h1><p>Thanks for joining us.</p>",
  text_body: "Welcome! Thanks for joining us."
}

# Send it (async by default)
{:ok, _job} = VcfNotifier.Email.FlexibleService.send_async(email)
```

### 3. Integration with Phoenix

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  
  def create(conn, %{"user" => user_params}) do
    case MyApp.Accounts.create_user(user_params) do
      {:ok, user} ->
        # Send welcome email asynchronously
        send_welcome_email(user)
        
        conn
        |> put_flash(:info, "Account created! Check your email.")
        |> redirect(to: Routes.user_path(conn, :show, user))
        
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  
  defp send_welcome_email(user) do
    email = %VcfNotifier.Email{
      to: [user.email],
      from: "welcome@myapp.com",
      subject: "Welcome to MyApp, #{user.name}!",
      html_body: MyApp.EmailTemplates.render("welcome.html", user: user)
    }
    
    VcfNotifier.Email.FlexibleService.send_async(email)
  end
end
```

## Clean API with Notification Alias

For backward compatibility and cleaner syntax:

```elixir
# These work the same way
VcfNotifier.send_async(notification)
Notification.send_async(notification)  # Cleaner!
```

## Advanced Features

### Bulk Email Sending

```elixir
# Define how to build each email
builder_fn = fn user_id ->
  user = MyApp.get_user!(user_id)
  %VcfNotifier.Email{
    to: [user.email],
    subject: "Newsletter",
    html_body: render_newsletter(user)
  }
end

# Send to thousands of users efficiently
VcfNotifier.Email.FlexibleService.send_bulk_with_builder(builder_fn, user_ids)
```

### Scheduled Delivery

```elixir
# Send in 1 hour
VcfNotifier.Email.FlexibleService.send_in(email, 3600)

# Send at specific time
VcfNotifier.Email.FlexibleService.send_at(email, ~U[2024-12-25 09:00:00Z])
```

### File Attachments

```elixir
email = %VcfNotifier.Email{
  to: ["customer@example.com"],
  subject: "Your Invoice",
  attachments: [
    %{
      filename: "invoice.pdf",
      data: pdf_binary,
      content_type: "application/pdf"
    }
  ]
}
```

## Supported Providers

- **SMTP** - Any SMTP server
- **SendGrid** - High deliverability email service
- **Mailgun** - Developer-focused email API
- **More coming soon** - AWS SES, Postmark, etc.

## Coming Soon

- 📱 SMS notifications (Twilio, AWS SNS)
- 🔔 Push notifications (FCM, APNS)
- 🔗 Webhook notifications
- 📊 Delivery tracking and analytics

## Documentation

- [Complete Usage Examples](USAGE_EXAMPLES.md)
- [Design Philosophy](DESIGN_PHILOSOPHY.md)
- [API Documentation](https://hexdocs.pm/vcf_notifier)

## Why This Architecture?

Unlike other notification libraries that try to handle everything, VcfNotifier focuses on:

1. **Your app builds emails** using your existing templates and data access
2. **VcfNotifier handles delivery** with reliable queuing and provider management
3. **Easy testing** since email building is separated from delivery
4. **Gradual adoption** - migrate existing email systems piece by piece


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
