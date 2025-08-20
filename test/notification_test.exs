defmodule NotificationTest do
  use ExUnit.Case, async: true
  doctest Notification

  alias VcfNotifier.Notification, as: VcfNotification

  describe "Notification alias module" do
    test "send/1 delegates to VcfNotifier.send/1" do
      attrs = %{
        type: :email,
        to: "test@example.com",
        subject: "Test Subject",
        body: "Test Body"
      }

      assert {:ok, %VcfNotification{status: :sent}} = Notification.send(attrs)
    end

    test "send_async/2 delegates to VcfNotifier.send_async/2" do
      attrs = %{
        type: :sms,
        to: "+1234567890",
        body: "Async SMS"
      }

      {:ok, task} = Notification.send_async(attrs)
      assert {:ok, %VcfNotification{status: :sent}} = Task.await(task)
    end

    test "handlers/0 delegates to VcfNotifier.handlers/0" do
      assert Notification.handlers() == VcfNotifier.handlers()
    end

    test "version/0 delegates to VcfNotifier.version/0" do
      assert Notification.version() == VcfNotifier.version()
    end

    test "send_bulk_email/3 delegates to VcfNotifier.send_bulk_email/3" do
      recipients = ["user1@example.com", "user2@example.com"]
      email_data = %{
        subject: "Test Bulk",
        body: "Bulk email test"
      }

      # In test mode, this should work with the test email provider
      result = Notification.send_bulk_email(recipients, email_data)
      assert match?({:ok, _jobs}, result)
    end
  end
end
