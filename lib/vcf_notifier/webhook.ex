defmodule VcfNotifier.Webhook do
  @behaviour VcfNotifier.NotificationBehaviour

  @impl VcfNotifier.NotificationBehaviour
  def send(attrs), do: {:ok, {:webhook, attrs}}

  @impl VcfNotifier.NotificationBehaviour
  def send_async(attrs, opts \\ []), do: {:ok, {:webhook_async, attrs, opts}}

  @impl VcfNotifier.NotificationBehaviour
  def send_at(attrs, datetime, opts \\ []), do: {:ok, {:webhook_at, attrs, datetime, opts}}

  @impl VcfNotifier.NotificationBehaviour
  def send_in(attrs, delay_seconds, opts \\ []), do: {:ok, {:webhook_in, attrs, delay_seconds, opts}}
end
