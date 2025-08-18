defmodule VcfNotifier.Sender do
  @moduledoc """
  Handles the sending of notifications through various channels.
  """

  alias VcfNotifier.Notification
  require Logger

  @doc """
  Sends a notification through the appropriate channel.
  """
  @spec send(Notification.t()) :: {:ok, Notification.t()} | {:error, term()}
  def send(%Notification{} = notification) do
    Logger.info("Sending #{notification.type} notification to #{notification.to}")

    # For now, we'll just log the notification
    # In a real implementation, this would delegate to specific handlers
    case send_via_channel(notification) do
      :ok ->
        {:ok, Notification.mark_as_sent(notification)}

      {:error, reason} = error ->
        Logger.error("Failed to send notification: #{inspect(reason)}")
        error
    end
  end

  # Private function to handle different notification types
  # This is where you'll plug in actual sending logic later
  defp send_via_channel(%Notification{type: :email} = notification) do
    # Placeholder for email sending logic
    Logger.debug("Email would be sent to #{notification.to}")
    Logger.debug("Subject: #{notification.subject}")
    Logger.debug("Body: #{notification.body}")
    :ok
  end

  defp send_via_channel(%Notification{type: :sms} = notification) do
    # Placeholder for SMS sending logic
    Logger.debug("SMS would be sent to #{notification.to}")
    Logger.debug("Message: #{notification.body}")
    :ok
  end

  defp send_via_channel(%Notification{type: :push} = notification) do
    # Placeholder for push notification logic
    Logger.debug("Push notification would be sent to #{notification.to}")
    Logger.debug("Message: #{notification.body}")
    :ok
  end

  defp send_via_channel(%Notification{type: :webhook} = notification) do
    # Placeholder for webhook logic
    Logger.debug("Webhook would be called: #{notification.to}")
    Logger.debug("Payload: #{notification.body}")
    :ok
  end

  defp send_via_channel(%Notification{type: unsupported_type}) do
    {:error, "Unsupported notification type: #{inspect(unsupported_type)}"}
  end
end
