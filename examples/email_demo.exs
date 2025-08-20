#!/usr/bin/env elixir

# Example usage of VcfNotifier with email notifications
# This script demonstrates various email notification features

Mix.install([
  {:vcf_notifier, path: "."}
])

# Configure for the example (normally done in config files)
Application.put_env(:vcf_notifier, :email_provider, :test)
Application.put_env(:vcf_notifier, :default_from_email, "noreply@example.com")
Application.put_env(:vcf_notifier, :email_providers, test: %{})

# Start the application
{:ok, _} = VcfNotifier.Application.start(:normal, [])

IO.puts("=== VcfNotifier Email Examples ===\n")

# Example 1: Simple email
IO.puts("1. Sending a simple email notification...")
{:ok, notification} = VcfNotifier.send(%{
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
{:ok, _notification} = VcfNotifier.send(%{
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
{:ok, _notification} = VcfNotifier.send(%{
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

# Example 4: Background email processing (simulated)
IO.puts("\n4. Enqueueing emails for background processing...")
emails_to_send = [
  %{
    type: :email,
    to: "user1@example.com",
    subject: "Newsletter #1",
    body: "Your weekly newsletter is here!"
  },
  %{
    type: :email,
    to: "user2@example.com",
    subject: "Newsletter #2",
    body: "Your weekly newsletter is here!"
  },
  %{
    type: :email,
    to: "user3@example.com",
    subject: "Newsletter #3",
    body: "Your weekly newsletter is here!"
  }
]

# In a real application with Oban configured, these would be processed in the background
for email <- emails_to_send do
  case VcfNotifier.send_async(email) do
    {:ok, _job} -> IO.puts("✓ Email queued for #{email.to}")
    {:error, reason} -> IO.puts("✗ Failed to queue email: #{inspect(reason)}")
  end
end

# Example 5: Bulk email sending
IO.puts("\n5. Sending bulk emails...")
recipients = ["user1@example.com", "user2@example.com", "user3@example.com"]
email_data = %{
  subject: "Bulk Newsletter",
  body: "This is our monthly newsletter!",
  metadata: %{
    html_body: "<h1>Monthly Newsletter</h1><p>Content here...</p>"
  }
}

case VcfNotifier.send_bulk_email(recipients, email_data) do
  {:ok, jobs} ->
    IO.puts("✓ #{length(jobs)} bulk emails queued successfully")
  {:error, reason} ->
    IO.puts("✗ Bulk email failed: #{inspect(reason)}")
end

IO.puts("\n=== All examples completed! ===")
IO.puts("\nNote: In this demo, we're using the test email adapter.")
IO.puts("In a real application, you would configure SMTP, SendGrid, or another provider.")
