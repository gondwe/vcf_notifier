# Simple test script to verify Notification alias works
IO.puts("Testing Notification alias...")

# Configure test environment
Application.put_env(:vcf_notifier, :email_provider, :test)

# Test basic send
notification = %{
  type: :email,
  to: "test@example.com",
  subject: "Test via Notification alias",
  body: "This email was sent using the Notification.send/1 function!"
}

IO.puts("Sending email using Notification.send/1...")
result = Notification.send(notification)
IO.puts("Result: #{inspect(result)}")

# Test async send
IO.puts("\nSending email using Notification.send_async/1...")
async_result = Notification.send_async(notification)
IO.puts("Async result: #{inspect(async_result)}")

# Test bulk email
IO.puts("\nSending bulk email using Notification.send_bulk_email/3...")
recipients = ["user1@example.com", "user2@example.com"]
email_data = %{subject: "Bulk Test", body: "This is a bulk email test!"}
bulk_result = Notification.send_bulk_email(recipients, email_data)
IO.puts("Bulk result: #{inspect(bulk_result)}")

# Test that new functions are automatically proxied
IO.puts("\nTesting automatic proxy of new function...")
auto_proxy_result = Notification.test_auto_proxy("Hello from macro proxy!")
IO.puts("Auto proxy result: #{auto_proxy_result}")

IO.puts("\n✅ All Notification alias tests completed successfully!")
