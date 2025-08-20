defmodule VcfNotifier.Email do
  @moduledoc """
  Email struct and functionality for email notifications.
  """

  import Swoosh.Email

  @type t :: %__MODULE__{
    to: list(String.t()) | String.t(),
    from: String.t(),
    subject: String.t(),
    text_body: String.t() | nil,
    html_body: String.t() | nil,
    cc: list(String.t()),
    bcc: list(String.t()),
    reply_to: String.t() | nil,
    attachments: list(map()),
    headers: map(),
    provider_options: map()
  }

  defstruct [
    :to,
    :from,
    :subject,
    :text_body,
    :html_body,
    cc: [],
    bcc: [],
    reply_to: nil,
    attachments: [],
    headers: %{},
    provider_options: %{}
  ]

  @doc """
  Creates an email struct from a notification.
  """
  @spec from_notification(VcfNotifier.Notification.t()) :: {:ok, t()} | {:error, String.t()}
  def from_notification(%VcfNotifier.Notification{type: :email} = notification) do
    metadata = notification.metadata || %{}

    email = %__MODULE__{
      to: normalize_recipients(notification.to),
      from: get_from_address(metadata),
      subject: notification.subject || "Notification",
      text_body: notification.body,
      html_body: Map.get(metadata, :html_body),
      cc: Map.get(metadata, :cc, []) |> normalize_recipients(),
      bcc: Map.get(metadata, :bcc, []) |> normalize_recipients(),
      reply_to: Map.get(metadata, :reply_to),
      attachments: Map.get(metadata, :attachments, []),
      headers: Map.get(metadata, :headers, %{}),
      provider_options: Map.get(metadata, :provider_options, %{})
    }

    case validate_email(email) do
      :ok -> {:ok, email}
      error -> error
    end
  end

  def from_notification(%VcfNotifier.Notification{type: type}) do
    {:error, "Expected email notification, got: #{type}"}
  end

  @doc """
  Converts the email struct to a Swoosh.Email struct.
  """
  @spec to_swoosh_email(t()) :: Swoosh.Email.t()
  def to_swoosh_email(%__MODULE__{} = email) do
    swoosh_email =
      new()
      |> to(email.to)
      |> from(email.from)
      |> subject(email.subject)

    swoosh_email =
      if email.text_body do
        text_body(swoosh_email, email.text_body)
      else
        swoosh_email
      end

    swoosh_email =
      if email.html_body do
        html_body(swoosh_email, email.html_body)
      else
        swoosh_email
      end

    swoosh_email =
      if length(email.cc) > 0 do
        cc(swoosh_email, email.cc)
      else
        swoosh_email
      end

    swoosh_email =
      if length(email.bcc) > 0 do
        bcc(swoosh_email, email.bcc)
      else
        swoosh_email
      end

    swoosh_email =
      if email.reply_to do
        reply_to(swoosh_email, email.reply_to)
      else
        swoosh_email
      end

    # Add attachments
    swoosh_email =
      Enum.reduce(email.attachments, swoosh_email, fn attachment, acc ->
        attachment(acc, attachment)
      end)

    # Add headers
    Enum.reduce(email.headers, swoosh_email, fn {key, value}, acc ->
      header(acc, key, value)
    end)
  end

  @doc """
  Validates the email struct.
  """
  @spec validate_email(t()) :: :ok | {:error, String.t()}
  def validate_email(%__MODULE__{} = email) do
    cond do
      is_nil(email.to) or email.to == [] ->
        {:error, "Email must have at least one recipient"}

      is_nil(email.from) or email.from == "" ->
        {:error, "Email must have a from address"}

      is_nil(email.subject) or email.subject == "" ->
        {:error, "Email must have a subject"}

      is_nil(email.text_body) and is_nil(email.html_body) ->
        {:error, "Email must have either text_body or html_body"}

      true ->
        :ok
    end
  end

  # Private helper functions

  defp normalize_recipients(recipients) when is_list(recipients), do: recipients
  defp normalize_recipients(recipient) when is_binary(recipient), do: [recipient]
  defp normalize_recipients(_), do: []

  defp get_from_address(metadata) do
    metadata
    |> Map.get(:from, get_default_from_address())
  end

  defp get_default_from_address do
    Application.get_env(:vcf_notifier, :default_from_email, "noreply@example.com")
  end
end
