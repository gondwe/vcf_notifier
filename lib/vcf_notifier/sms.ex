defmodule VcfNotifier.SMS do
  @behaviour VcfNotifier.NotificationBehaviour

  @impl VcfNotifier.NotificationBehaviour
  def send(attrs) do
    # Stub implementation - would integrate with SMS provider
    notification =
      case attrs do
        %VcfNotifier.Notification{} = n -> n
        map when is_map(map) -> struct(VcfNotifier.Notification, Map.put(map, :type, :sms))
      end

    # Simulate SMS sending
    VcfNotifier.Sender.send(notification)
  end

  @impl VcfNotifier.NotificationBehaviour
  def send_async(attrs, _opts \\ []) do
    # Return a proper Task for async operations
    task = Task.async(fn -> send(attrs) end)
    {:ok, task}
  end

  @impl VcfNotifier.NotificationBehaviour
  def send_at(_attrs, _datetime, _opts \\ []), do: {:error, "Scheduled SMS not implemented yet"}

  @impl VcfNotifier.NotificationBehaviour
  def send_in(_attrs, _delay_seconds, _opts \\ []), do: {:error, "Delayed SMS not implemented yet"}
end
