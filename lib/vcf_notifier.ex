defmodule VcfNotifier do
  @moduledoc """
  VcfNotifier is a flexible notification library for Elixir applications.

  It provides a simple interface for sending notifications through various channels
  like email, SMS, push notifications, etc.

  ## Usage

      # Send a notification
      VcfNotifier.send(%{
        type: :email,
        to: "user@example.com",
        subject: "Hello",
        body: "This is a test notification"
      })

  """

  alias VcfNotifier.{Notification, Sender}

  @doc """
  Sends a notification based on the provided attributes.

  ## Parameters

    - attrs: A map containing notification details
      - :type - The notification type (e.g., :email, :sms)
      - :to - The recipient
      - :subject - The notification subject (optional for some types)
      - :body - The notification body
      - Additional fields based on notification type

  ## Examples

      iex> VcfNotifier.send(%{type: :email, to: "test@example.com", subject: "Test", body: "Hello"})
  """
  @spec send(map()) :: {:ok, Notification.t()} | {:error, term()}
  def send(attrs) when is_map(attrs) do
    with {:ok, notification} <- Notification.build(attrs) do
      Sender.send(notification)
    end
  end

  @doc """
  Sends a notification asynchronously.

  Returns immediately with a task that can be awaited.
  """
  @spec send_async(map()) :: Task.t()
  def send_async(attrs) when is_map(attrs) do
    Task.async(fn -> send(attrs) end)
  end

  @doc """
  Returns the configured notification handlers.
  """
  @spec handlers() :: list(atom())
  def handlers do
    [:email, :sms, :push, :webhook]
  end

  @doc """
  Returns the library version.
  """
  @spec version() :: String.t()
  def version do
    Application.spec(:vcf_notifier, :vsn) |> to_string()
  end
end
