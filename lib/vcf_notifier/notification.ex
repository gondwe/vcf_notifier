defmodule VcfNotifier.Notification do
  @moduledoc """
  Represents a notification to be sent.
  """

  @type t :: %__MODULE__{
          type: atom(),
          to: String.t() | list(String.t()),
          subject: String.t() | nil,
          body: String.t(),
          metadata: map(),
          sent_at: DateTime.t() | nil,
          status: :pending | :sent | :failed
        }

  defstruct [:type, :to, :subject, :body, :metadata, :sent_at, status: :pending]

  @doc """
  Builds a notification struct from attributes.
  """
  @spec build(map()) :: {:ok, t()} | {:error, String.t()}
  def build(attrs) do
    with :ok <- validate_required(attrs),
         :ok <- validate_type(attrs[:type]) do
      notification = %__MODULE__{
        type: attrs[:type],
        to: attrs[:to],
        subject: attrs[:subject],
        body: attrs[:body],
        metadata: attrs[:metadata] || %{}
      }

      {:ok, notification}
    end
  end

  defp validate_required(attrs) do
    required = [:type, :to, :body]
    missing = required -- Map.keys(attrs)

    if missing == [] do
      :ok
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  defp validate_type(type) when type in [:email, :sms, :push, :webhook], do: :ok
  defp validate_type(type), do: {:error, "Unsupported notification type: #{inspect(type)}"}

  @doc """
  Marks a notification as sent.
  """
  @spec mark_as_sent(t()) :: t()
  def mark_as_sent(%__MODULE__{} = notification) do
    %{notification | status: :sent, sent_at: DateTime.utc_now()}
  end

  @doc """
  Marks a notification as failed.
  """
  @spec mark_as_failed(t()) :: t()
  def mark_as_failed(%__MODULE__{} = notification) do
    %{notification | status: :failed}
  end
end
