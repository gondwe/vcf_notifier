defmodule VcfNotifier.Email.Service do
  @moduledoc """
  High-level email service that coordinates email sending with queue management.

  Provides both synchronous and asynchronous email sending options.
  """

  alias VcfNotifier.{Email, Notification}
  alias VcfNotifier.Email.Provider
  alias VcfNotifier.Workers.EmailWorker
  require Logger

  @doc """
  Sends an email notification synchronously.
  """
  @spec send_now(Notification.t()) :: {:ok, Notification.t()} | {:error, term()}
  def send_now(%Notification{type: :email} = notification) do
    Logger.info("Sending email immediately to #{notification.to}")

    with {:ok, email} <- Email.from_notification(notification),
         {:ok, _response} <- Provider.send_email(email) do
      # Return the notification marked as sent
      {:ok, Notification.mark_as_sent(notification)}
    end
  end

  def send_now(%Notification{type: type}) do
    {:error, "Expected email notification, got: #{type}"}
  end

  @doc """
  Enqueues an email notification for background processing.
  """
  @spec send_async(Notification.t(), keyword()) :: {:ok, Oban.Job.t()} | {:error, term()}
  def send_async(%Notification{} = notification, opts \\ []) do
    EmailWorker.enqueue(notification, opts)
  end

  @doc """
  Schedules an email to be sent at a specific time.
  """
  @spec send_at(Notification.t(), DateTime.t(), keyword()) :: {:ok, Oban.Job.t()} | {:error, term()}
  def send_at(%Notification{} = notification, %DateTime{} = send_time, opts \\ []) do
    EmailWorker.enqueue_in(notification, send_time, opts)
  end

  @doc """
  Schedules an email to be sent after a delay (in seconds).
  """
  @spec send_in(Notification.t(), integer(), keyword()) :: {:ok, Oban.Job.t()} | {:error, term()}
  def send_in(%Notification{} = notification, delay_seconds, opts \\ []) do
    EmailWorker.enqueue_in(notification, delay_seconds, opts)
  end

  @doc """
  Sends a bulk email notification to multiple recipients.
  Each recipient gets their own job for better error handling and tracking.
  """
  @spec send_bulk(list(String.t()), map(), keyword()) :: {:ok, list(Oban.Job.t())} | {:error, term()}
  def send_bulk(recipients, email_data, opts \\ []) when is_list(recipients) and is_map(email_data) do
    jobs =
      recipients
      |> Enum.map(fn recipient ->
        notification_attrs = Map.put(email_data, :to, recipient)

        case Notification.build(notification_attrs) do
          {:ok, notification} ->
            send_async(notification, opts)

          {:error, _reason} = error ->
            error
        end
      end)

    # Check if any jobs failed to be created
    errors = Enum.filter(jobs, &match?({:error, _}, &1))

    if length(errors) > 0 do
      {:error, "Failed to create #{length(errors)} jobs: #{inspect(errors)}"}
    else
      successful_jobs = Enum.map(jobs, fn {:ok, job} -> job end)
      {:ok, successful_jobs}
    end
  end

  @doc """
  Gets email delivery statistics for monitoring.
  """
  @spec get_stats(keyword()) :: map()
  def get_stats(opts \\ []) do
    # For now, return basic stats from Oban
    # In a real implementation, you'd query the configured repo
    queue_name = Keyword.get(opts, :queue, :emails)

    # This is a simplified version - in practice you'd need to configure
    # and use your application's Repo
    %{
      available: 0,
      scheduled: 0,
      executing: 0,
      retryable: 0,
      completed: 0,
      discarded: 0,
      cancelled: 0,
      queue: queue_name
    }
  end

  # Private functions (removed the complex query functions for now)
  # These would be implemented once the application has a proper Repo configured
end
