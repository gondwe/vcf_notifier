# Email Notifications with VcfNotifier

VcfNotifier provides comprehensive email notification support with background processing using Oban queues.

## Features

- **Multiple Email Providers**: Support for SMTP, SendGrid, Mailgun, Postmark, and Amazon SES
- **Background Processing**: Reliable email delivery using Oban workers
- **Scheduled Emails**: Send emails at specific times or after delays
- **Bulk Email Support**: Send to multiple recipients efficiently
- **Rich Email Content**: Support for HTML content, attachments, CC/BCC
- **Error Handling**: Automatic retries and comprehensive error logging
- **Monitoring**: Built-in statistics for email delivery tracking

## Quick Start

### 1. Add Dependencies

The required dependencies are automatically included when you add `vcf_notifier` to your project:

```elixir
# In your mix.exs
defp deps do
  [
    {:vcf_notifier, "~> 0.1.0"}
  ]
end
```

### 2. Configure Your Application

Add VcfNotifier configuration to your `config/config.exs`:

```elixir
import Config

# Configure your database repo (required for Oban)
config :vcf_notifier, 
  repo: MyApp.Repo

# Configure Oban for background jobs
config :vcf_notifier, Oban,
  repo: MyApp.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [
    emails: 10,
    default: 5
  ]

# Email configuration
config :vcf_notifier,
  email_provider: :smtp,
  default_from_email: "noreply@myapp.com"

# Email provider settings
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

### 3. Add to Your Supervision Tree

Add VcfNotifier to your application's supervision tree:

```elixir
# In your application.ex
def start(_type, _args) do
  children = [
    MyApp.Repo,
    MyAppWeb.Endpoint,
    # Add VcfNotifier
    VcfNotifier.Application
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Usage Examples

### Basic Email Sending

```elixir
# Send immediately (synchronous) - using the Notification alias
Notification.send(%{
  type: :email,
  to: "user@example.com",
  subject: "Welcome!",
  body: "Welcome to our service!"
})

# Send in background (asynchronous)
Notification.send_async(%{
  type: :email,
  to: "user@example.com",
  subject: "Welcome!",
  body: "Welcome to our service!"
})

# Alternative: Use VcfNotifier directly (both work the same way)
VcfNotifier.send(%{
  type: :email,
  to: "user@example.com",
  subject: "Welcome!",
  body: "Welcome to our service!"
})
```

### HTML Emails

```elixir
VcfNotifier.send_async(%{
  type: :email,
  to: "user@example.com",
  subject: "Welcome!",
  body: "Welcome to our service!",
  metadata: %{
    html_body: """
    <h1>Welcome!</h1>
    <p>Welcome to our service!</p>
    <p><a href="https://myapp.com/login">Login here</a></p>
    """,
    from: "welcome@myapp.com"
  }
})
```

### Email with CC/BCC and Reply-To

```elixir
VcfNotifier.send_async(%{
  type: :email,
  to: "user@example.com",
  subject: "Important Update",
  body: "This is an important update.",
  metadata: %{
    cc: ["manager@example.com"],
    bcc: ["audit@example.com"],
    reply_to: "support@myapp.com",
    from: "updates@myapp.com"
  }
})
```

### Scheduled Email Sending

```elixir
# Send after a delay (using Notification alias)
Notification.send_in(%{
  type: :email,
  to: "user@example.com",
  subject: "Reminder",
  body: "Don't forget about your appointment tomorrow!"
}, 3600)  # 1 hour delay

# Send at specific time
Notification.send_at(%{
  type: :email,
  to: "user@example.com",
  subject: "Meeting Tomorrow",
  body: "Your meeting is scheduled for 10 AM tomorrow."
}, ~U[2024-01-15 10:00:00Z])

# Using VcfNotifier directly (alternative syntax)
VcfNotifier.send_in(email_notification, 3600)
VcfNotifier.send_at(email_notification, ~U[2024-01-15 10:00:00Z])
```

### Bulk Emails

### Bulk Email Sending

```elixir
recipients = ["user1@example.com", "user2@example.com", "user3@example.com"]

# Send bulk emails (using Notification alias - recommended)
Notification.send_bulk_email(recipients, "Newsletter", "Check out our latest updates!")

# Alternative using VcfNotifier directly
VcfNotifier.send_bulk_email(recipients, "Newsletter", "Check out our latest updates!")
```

## Email Providers

### SMTP Configuration

```elixir
config :vcf_notifier, :email_providers,
  smtp: %{
    host: "smtp.gmail.com",
    port: 587,
    username: "your-email@gmail.com",
    password: "your-app-password",
    ssl: false,
    tls: :if_available,
    auth: :always,
    retries: 1
  }
```

### SendGrid Configuration

```elixir
config :vcf_notifier,
  email_provider: :sendgrid

config :vcf_notifier, :email_providers,
  sendgrid: %{
    api_key: "your-sendgrid-api-key"
  }
```

### Mailgun Configuration

```elixir
config :vcf_notifier,
  email_provider: :mailgun

config :vcf_notifier, :email_providers,
  mailgun: %{
    api_key: "your-mailgun-api-key",
    domain: "your-domain.com"
  }
```

### Postmark Configuration

```elixir
config :vcf_notifier,
  email_provider: :postmark

config :vcf_notifier, :email_providers,
  postmark: %{
    api_key: "your-postmark-api-key"
  }
```

### Amazon SES Configuration

```elixir
config :vcf_notifier,
  email_provider: :ses

config :vcf_notifier, :email_providers,
  ses: %{
    access_key: "your-aws-access-key",
    secret_key: "your-aws-secret-key",
    region: "us-east-1"
  }
```

## Advanced Features

### Email with Attachments

```elixir
VcfNotifier.send_async(%{
  type: :email,
  to: "user@example.com",
  subject: "Invoice Attached",
  body: "Please find your invoice attached.",
  metadata: %{
    attachments: [
      %{
        filename: "invoice.pdf",
        content_type: "application/pdf",
        data: File.read!("path/to/invoice.pdf")
      }
    ]
  }
})
```

### Custom Headers

```elixir
VcfNotifier.send_async(%{
  type: :email,
  to: "user@example.com",
  subject: "Custom Headers",
  body: "Email with custom headers.",
  metadata: %{
    headers: %{
      "X-Campaign-ID" => "campaign_123",
      "X-Source" => "newsletter"
    }
  }
})
```

### Priority and Retries

```elixir
# High priority email with custom retry settings
VcfNotifier.send_async(%{
  type: :email,
  to: "urgent@example.com",
  subject: "Urgent Notification",
  body: "This is urgent!"
}, priority: 1, max_attempts: 5)
```

## Monitoring and Statistics

```elixir
# Get email delivery statistics
stats = VcfNotifier.Email.Service.get_stats()
# Returns: %{available: 0, scheduled: 2, executing: 0, retryable: 1, completed: 15, discarded: 0, cancelled: 0}

# Get stats for specific timeframe
stats = VcfNotifier.Email.Service.get_stats(timeframe: :last_hour)
```

## Error Handling

VcfNotifier provides comprehensive error handling:

- **Automatic Retries**: Failed emails are automatically retried up to 3 times
- **Dead Letter Queue**: Emails that fail all retries are moved to a dead letter queue
- **Detailed Logging**: All email operations are logged with detailed error information
- **Provider Fallback**: You can configure multiple providers for redundancy

## Testing

For testing, configure a test email adapter:

```elixir
# In config/test.exs
config :vcf_notifier, Oban,
  testing: :manual,
  queues: false

config :swoosh, :api_client, false
```

Then in your tests:

```elixir
test "sends welcome email" do
  assert {:ok, _job} = VcfNotifier.send_async(%{
    type: :email,
    to: "test@example.com",
    subject: "Welcome!",
    body: "Welcome!"
  })
  
  # Verify the job was enqueued
  assert_enqueued(worker: VcfNotifier.Workers.EmailWorker)
end
```

## Troubleshooting

### Common Issues

1. **Database Connection Error**: Ensure your Repo is properly configured in the Oban settings
2. **Email Provider Authentication**: Double-check your API keys and credentials
3. **Queue Not Processing**: Make sure Oban is properly started in your supervision tree
4. **Rate Limiting**: Some providers have rate limits; adjust your queue concurrency accordingly

### Debugging

Enable debug logging to see detailed email operations:

```elixir
config :logger, level: :debug
```

Check Oban's web interface for job monitoring:

```elixir
# In your router
scope "/admin" do
  pipe_through :admin_auth
  live "/oban", Oban.Web.JobLive, layout: {MyAppWeb.LayoutView, "live.html"}
end
```
