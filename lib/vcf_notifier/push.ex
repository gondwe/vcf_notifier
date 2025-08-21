defmodule VcfNotifier.Push do
  @behaviour VcfNotifier.NotificationBehaviour

  @impl VcfNotifier.NotificationBehaviour
  def send(attrs), do: {:ok, {:push, attrs}}

  @impl VcfNotifier.NotificationBehaviour
  def send_async(attrs, opts \\ []), do: {:ok, {:push_async, attrs, opts}}

  @impl VcfNotifier.NotificationBehaviour
  def send_at(attrs, datetime, opts \\ []), do: {:ok, {:push_at, attrs, datetime, opts}}

  @impl VcfNotifier.NotificationBehaviour
  def send_in(attrs, delay_seconds, opts \\ []), do: {:ok, {:push_in, attrs, delay_seconds, opts}}
end
