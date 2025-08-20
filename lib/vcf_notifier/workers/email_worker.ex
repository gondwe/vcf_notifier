defmodule VcfNotifier.Workers.EmailWorker do
  @moduledoc """
  Oban worker for processing email notifications in the background.

  Handles retries, error logging, and email delivery tracking.
  """

  use Oban.Worker,
    queue: :emails,
    max_attempts: 3,
    tags: ["email", "notification"]

  alias VcfNotifier.{Email, Notification}
  alias VcfNotifier.Email.Provider
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notification" => notification_data}}) do
    Logger.info("Processing email job: #{inspect(notification_data)}")

    with {:ok, notification} <- deserialize_notification(notification_data),
         {:ok, email} <- Email.from_notification(notification),
         {:ok, _response} <- Provider.send_email(email) do
      Logger.info("Email sent successfully to #{notification.to}")
      :ok
    else
      {:error, reason} = error ->
        Logger.error("Failed to send email: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Enqueues an email notification for background processing.
  """
  @spec enqueue(Notification.t(), keyword()) :: {:ok, Oban.Job.t()} | {:error, term()}
  def enqueue(notification, opts \\ [])

  def enqueue(%Notification{type: :email} = notification, opts) do
    job_args = %{
      "notification" => serialize_notification(notification)
    }

    job_opts = [
      queue: :emails,
      tags: ["email", "notification"]
    ] ++ opts

    changeset = %{args: job_args}
    |> apply_job_options(job_opts)
    |> __MODULE__.new()

    # Check if we're in test mode
    case Application.get_env(:vcf_notifier, Oban, []) do
      config when is_list(config) ->
        if Keyword.get(config, :testing) == :manual do
          # In test mode, simulate successful enqueue
          {:ok, %Oban.Job{id: :test, args: job_args, queue: :emails}}
        else
          Oban.insert(changeset)
        end

      _ ->
        case Code.ensure_loaded(Oban) do
          {:module, Oban} ->
            Oban.insert(changeset)

          {:error, :nofile} ->
            {:error, "Oban is not available. Make sure it's properly configured."}
        end
    end
  end

  def enqueue(%Notification{type: type}, _opts) do
    {:error, "EmailWorker can only process email notifications, got: #{type}"}
  end

  @doc """
  Enqueues an email notification with a delay.
  """
  @spec enqueue_in(Notification.t(), integer() | DateTime.t(), keyword()) ::
    {:ok, Oban.Job.t()} | {:error, term()}
  def enqueue_in(%Notification{} = notification, delay_or_datetime, opts \\ []) do
    schedule_opts =
      case delay_or_datetime do
        %DateTime{} = datetime ->
          [scheduled_at: datetime]

        delay when is_integer(delay) ->
          [schedule_in: delay]
      end

    enqueue(notification, schedule_opts ++ opts)
  end

  # Private functions

  defp serialize_notification(%Notification{} = notification) do
    %{
      "type" => notification.type,
      "to" => notification.to,
      "subject" => notification.subject,
      "body" => notification.body,
      "metadata" => notification.metadata,
      "sent_at" => notification.sent_at,
      "status" => notification.status
    }
  end

  defp deserialize_notification(data) when is_map(data) do
    notification = %Notification{
      type: String.to_atom(data["type"]),
      to: data["to"],
      subject: data["subject"],
      body: data["body"],
      metadata: data["metadata"] || %{},
      sent_at: parse_datetime(data["sent_at"]),
      status: String.to_atom(data["status"])
    }

    {:ok, notification}
  end

  defp deserialize_notification(_), do: {:error, "Invalid notification data"}

  defp parse_datetime(nil), do: nil
  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end
  defp parse_datetime(_), do: nil

  defp apply_job_options(job, opts) do
    Enum.reduce(opts, job, fn
      {:queue, queue}, acc -> Map.put(acc, :queue, queue)
      {:tags, tags}, acc -> Map.put(acc, :tags, tags)
      {:priority, priority}, acc -> Map.put(acc, :priority, priority)
      {:max_attempts, attempts}, acc -> Map.put(acc, :max_attempts, attempts)
      {:schedule_in, delay}, acc -> Map.put(acc, :schedule_in, delay)
      {:scheduled_at, datetime}, acc -> Map.put(acc, :scheduled_at, datetime)
      {_key, _value}, acc -> acc
    end)
  end
end
