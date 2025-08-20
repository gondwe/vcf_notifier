defmodule VcfNotifier do
  @moduledoc """
  VcfNotifier is a flexible notification library for Elixir applications.

  It provides a simple interface for sending notifications through various channels
  like email, SMS, push notifications, etc. with support for background processing
  using Oban queues.

  ## Convenience Alias

  For a more intuitive API, you can use the `Notification` module which delegates
  all calls to this module:

      # Using the alias (recommended)
      Notification.send(%{type: :email, to: "user@example.com", subject: "Hello", body: "World"})

      # Using VcfNotifier directly (also works)
      VcfNotifier.send(%{type: :email, to: "user@example.com", subject: "Hello", body: "World"})

  ## Usage

      # Send an email notification immediately
      Notification.send(%{
        type: :email,
        to: "user@example.com",
        subject: "Hello",
        body: "This is a test notification"
      })

      # Send an email notification in the background
      Notification.send_async(%{
        type: :email,
        to: "user@example.com",
        subject: "Hello",
        body: "This is a test notification"
      })

      # Send an email with HTML content
      Notification.send_async(%{
        type: :email,
        to: "user@example.com",
        subject: "Welcome!",
        body: "Welcome to our service",
        metadata: %{
          html_body: "<h1>Welcome!</h1><p>Welcome to our service</p>",
          from: "welcome@yourcompany.com"
        }
      })

  """

  alias VcfNotifier.{Notification, Sender}
  alias VcfNotifier.Email.Service, as: EmailService

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
      case notification.type do
        :email -> EmailService.send_now(notification)
        _ -> Sender.send(notification)
      end
    end
  end

  @doc """
  Sends a notification asynchronously using background workers.

  For email notifications, uses Oban workers for reliable delivery.
  """
  @spec send_async(map(), keyword()) :: {:ok, Oban.Job.t() | Task.t()} | {:error, term()}
  def send_async(attrs, opts \\ []) when is_map(attrs) do
    with {:ok, notification} <- Notification.build(attrs) do
      case notification.type do
        :email ->
          EmailService.send_async(notification, opts)

        _ ->
          # For non-email notifications, use Task.async for now
          task = Task.async(fn -> Sender.send(notification) end)
          {:ok, task}
      end
    end
  end

  @doc """
  Schedules a notification to be sent at a specific time.
  Currently only supports email notifications.
  """
  @spec send_at(map(), DateTime.t(), keyword()) :: {:ok, Oban.Job.t()} | {:error, term()}
  def send_at(attrs, %DateTime{} = send_time, opts \\ []) when is_map(attrs) do
    with {:ok, notification} <- Notification.build(attrs) do
      case notification.type do
        :email -> EmailService.send_at(notification, send_time, opts)
        _ -> {:error, "Scheduled sending is only supported for email notifications"}
      end
    end
  end

  @doc """
  Schedules a notification to be sent after a delay (in seconds).
  Currently only supports email notifications.
  """
  @spec send_in(map(), integer(), keyword()) :: {:ok, Oban.Job.t()} | {:error, term()}
  def send_in(attrs, delay_seconds, opts \\ []) when is_map(attrs) and is_integer(delay_seconds) do
    with {:ok, notification} <- Notification.build(attrs) do
      case notification.type do
        :email -> EmailService.send_in(notification, delay_seconds, opts)
        _ -> {:error, "Delayed sending is only supported for email notifications"}
      end
    end
  end

  @doc """
  Sends bulk email notifications to multiple recipients.
  Each recipient gets their own background job for better error handling.
  """
  @spec send_bulk_email(list(String.t()), map(), keyword()) :: {:ok, list(Oban.Job.t())} | {:error, term()}
  def send_bulk_email(recipients, email_data, opts \\ []) when is_list(recipients) do
    email_attrs = Map.put(email_data, :type, :email)
    EmailService.send_bulk(recipients, email_attrs, opts)
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

  @doc """
  Test function to demonstrate automatic proxy functionality.
  This function will be automatically available through the Notification module.
  """
  @spec test_auto_proxy(String.t()) :: String.t()
  def test_auto_proxy(message) do
    "Auto-proxied: #{message}"
  end
end
