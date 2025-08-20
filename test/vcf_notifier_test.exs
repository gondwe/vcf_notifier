defmodule VcfNotifierTest do
  use ExUnit.Case
  doctest VcfNotifier

  alias VcfNotifier.Notification

  describe "send/1" do
    test "sends email notification successfully" do
      attrs = %{
        type: :email,
        to: "test@example.com",
        subject: "Test Subject",
        body: "Test Body"
      }

      assert {:ok, %Notification{status: :sent}} = VcfNotifier.send(attrs)
    end

    test "returns error for missing required fields" do
      attrs = %{type: :email}
      assert {:error, _} = VcfNotifier.send(attrs)
    end

    test "returns error for unsupported notification type" do
      attrs = %{
        type: :unsupported,
        to: "test@example.com",
        body: "Test Body"
      }

      assert {:error, "Unsupported notification type: :unsupported"} = VcfNotifier.send(attrs)
    end
  end

  describe "send_async/1" do
    test "sends notification asynchronously" do
      attrs = %{
        type: :sms,
        to: "+1234567890",
        body: "Async SMS"
      }

      {:ok, task} = VcfNotifier.send_async(attrs)
      assert {:ok, %Notification{status: :sent}} = Task.await(task)
    end
  end

  describe "handlers/0" do
    test "returns list of available handlers" do
      handlers = VcfNotifier.handlers()
      assert :email in handlers
      assert :sms in handlers
    end
  end
end
