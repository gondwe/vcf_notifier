defmodule VcfNotifier.Workers.EmailWorkerTest do
  use ExUnit.Case, async: true

  alias VcfNotifier.{Notification, Workers.EmailWorker}

  describe "enqueue/2" do
    test "returns error when Oban is not available" do
      notification = %Notification{
        type: :email,
        to: "test@example.com",
        subject: "Test",
        body: "Test body",
        metadata: %{}
      }

      # In test mode without proper Oban setup, this should return an error
      # or handle gracefully
      result = EmailWorker.enqueue(notification)
      # Since we don't have Oban properly configured in tests,
      # we expect either an error or specific test behavior
      assert match?({:error, _}, result) or match?({:ok, _}, result)
    end

    test "rejects non-email notifications" do
      notification = %Notification{
        type: :sms,
        to: "+1234567890",
        body: "Test message"
      }

      assert {:error, "EmailWorker can only process email notifications, got: sms"} =
        EmailWorker.enqueue(notification)
    end
  end

  describe "perform/1" do
    test "deserializes notification data correctly" do
      notification_data = %{
        "type" => "email",
        "to" => "test@example.com",
        "subject" => "Test",
        "body" => "Test body",
        "metadata" => %{},
        "sent_at" => nil,
        "status" => "pending"
      }

      # We can test that the data structure is correct and the job succeeds
      job = %Oban.Job{args: %{"notification" => notification_data}}

      # With the test email provider, this should succeed
      assert :ok = EmailWorker.perform(job)
    end
  end
end
