#!/usr/bin/env elixir

# Simple VcfNotifier Email Demo (Synchronous Only)
# This demonstrates synchronous email functionality without requiring Oban/database setup

Mix.install([
  {:vcf_notifier, path: "."}
])

# Configure for the example
Application.put_env(:vcf_notifier, :email_provider, :test)
Application.put_env(:vcf_notifier, :default_from_email, "noreply@example.com")
Application.put_env(:vcf_notifier, :email_providers, test: %{})
# Disable Swoosh API client to avoid hackney dependency
Application.put_env(:swoosh, :api_client, false)

# Start just the HTTP client
{:ok, _} = Finch.start_link(name: VcfNotifier.Finch)

IO.puts("=== VcfNotifier Email Demo (Using Notification Alias) ===\n")

# Example 1: Simple email
IO.puts("1. Sending a simple email notification...")
{:ok, notification} = Notification.send(%{
  type: :email,
  to: "user@example.com",
  subject: "Welcome!",
  body: "Welcome to our service!"
})
IO.puts("✓ Email sent successfully")
IO.puts("  Status: #{notification.status}")
IO.puts("  Sent at: #{notification.sent_at}")

# Example 2: Email with HTML content
IO.puts("\n2. Sending email with HTML content...")
{:ok, _notification} = Notification.send(%{
  type: :email,
  to: "user@example.com",
  subject: "HTML Email",
  body: "This is the plain text version",
  metadata: %{
    html_body: """
    <h1>Welcome!</h1>
    <p>This is an <strong>HTML</strong> email with rich formatting.</p>
    <ul>
      <li>Feature 1</li>
      <li>Feature 2</li>
      <li>Feature 3</li>
    </ul>
    """,
    from: "welcome@example.com"
  }
})
IO.puts("✓ HTML email sent successfully")

# Example 3: Email with CC and BCC
IO.puts("\n3. Sending email with CC and BCC...")
{:ok, _notification} = Notification.send(%{
  type: :email,
  to: "primary@example.com",
  subject: "Important Update",
  body: "This is an important update for all stakeholders.",
  metadata: %{
    cc: ["manager@example.com", "supervisor@example.com"],
    bcc: ["audit@example.com"],
    reply_to: "support@example.com"
  }
})
IO.puts("✓ Email with CC/BCC sent successfully")

# Example 4: Multiple recipients
IO.puts("\n4. Sending email to multiple recipients...")
{:ok, _notification} = Notification.send(%{
  type: :email,
  to: ["user1@example.com", "user2@example.com", "user3@example.com"],
  subject: "Team Announcement",
  body: "This announcement goes to the entire team."
})
IO.puts("✓ Multi-recipient email sent successfully")

# Example 5: Non-email notification (for comparison)
IO.puts("\n5. Sending SMS notification...")
{:ok, _notification} = Notification.send(%{
  type: :sms,
  to: "+1234567890",
  body: "Your verification code is: 123456"
})
IO.puts("✓ SMS notification sent successfully")

IO.puts("\n=== Demo completed successfully! ===")
IO.puts("\nWhat just happened:")
IO.puts("- All emails used the 'test' provider (no actual emails sent)")
IO.puts("- Emails were processed synchronously")
IO.puts("- The library handled validation, formatting, and delivery")
IO.puts("- Non-email notifications (SMS) also work through the same interface")
IO.puts("- You can use either Notification.send/1 or VcfNotifier.send/1 (they're equivalent)")
IO.puts("\nIn a real application with proper configuration:")
IO.puts("- Emails would be sent through your chosen provider (SMTP, SendGrid, etc.)")
IO.puts("- Background processing would handle high-volume sending")
IO.puts("- Oban would manage retries and job scheduling")
IO.puts("- Full monitoring and analytics would be available")
