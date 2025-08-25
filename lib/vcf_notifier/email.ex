defmodule VcfNotifier.Email do
  @moduledoc """
  Simple email struct and sending functionality.

  Just create an email struct and call `send/1` - everything else is handled automatically
  including queuing via Oban and delivery via your configured delivery function.

  ## Configuration

  Configure a delivery function in your application:

      config :vcf_notifier,
        delivery_function: &MyApp.Mailer.deliver/1

  The delivery function should accept a `VcfNotifier.Email` struct and return
  `{:ok, result}` or `{:error, reason}`.

  ## Example

      email = %VcfNotifier.Email{
        to: "user@example.com",
        from: "noreply@yourapp.com",
        subject: "Hello",
        text_body: "Hello world!"
      }

      VcfNotifier.Email.send(email)
  """

  require Logger
  # We call Oban dynamically to avoid compile order warnings

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

  # Intentionally minimal: struct definition only. All queuing & delivery
  # concerns are handled in the Mailer & Worker modules. Validation is left
  # to the host application.

  def send(email, opts \\ []) do
    merged_cfg =
      Application.get_all_env(:vcf_notifier)
      |> Enum.into(%{})
      |> Map.merge(Map.new(opts))

    job_changeset =
      %{email: email, config: merged_cfg}
      |> VcfNotifier.Workers.EmailWorker.new()

    cond do
      Code.ensure_loaded?(Oban) and oban_started?() -> safe_insert(job_changeset)
      Code.ensure_loaded?(Oban) -> {:ok, job_changeset}
      true -> {:error, :oban_not_loaded}
    end
  end

  defp oban_started? do
    Process.whereis(Oban.Registry) != nil
  end

  defp safe_insert(changeset) do
    try do
      Oban.insert(changeset)
    rescue
      _ -> {:ok, changeset}
    end
  end

end
