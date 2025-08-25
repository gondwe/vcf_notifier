defmodule VcfNotifier.Mailer do
  @moduledoc """
  Minimal delivery adapter: turns a map into a Bamboo.Email and delivers it.

  Optional config (all optional):

      config :vcf_notifier,
        default_from: {\"VcfNotifier\", \"no-reply@localhost\"},
        default_subject: \"Notification\"

  If :from or :subject are missing in the email map, these defaults are used.
  :to must always be provided by the caller and will raise if absent.
  Queue / job creation is handled outside this module (e.g. via an Oban worker).
  """

  use Bamboo.Mailer, otp_app: :vcf_notifier
  import Bamboo.Email
  require Logger

  @type email_data :: map() | struct()

  # Called by the worker to actually deliver using Bamboo.
  def send(%{} = email, config) when map_size(email) > 0 do
    email
    |> build_bamboo_email(config)
    |> deliver_now()

    :ok
  end

  def send(email, _opts) do
    Logger.error("Email delivery failed: #{inspect(email)}")
    {:error, email}
  end

  defp build_bamboo_email(d, cfg) do
    to_value = d[:to] || d["to"] || raise ArgumentError, "missing :to (recipient)"
    from_value = d[:from] || d["from"] || cfg[:default_from] || cfg["default_from"] || default_from()
    subject_value = d[:subject] || d["subject"] || cfg[:default_subject] || cfg["default_subject"] || default_subject()

    email =
      new_email()
      |> to(List.wrap(to_value))
      |> from(from_value)
      |> subject(subject_value)

    email =
      case d[:text_body] || d["text_body"] do
        nil -> email
        txt -> text_body(email, txt)
      end

    email =
      case d[:html_body] || d["html_body"] do
        nil -> email
        html -> html_body(email, html)
      end

    email =
      case d[:cc] || d["cc"] do
        nil -> email
        cc_vals -> cc(email, List.wrap(cc_vals))
      end

    email =
      case d[:bcc] || d["bcc"] do
        nil -> email
        bcc_vals -> bcc(email, List.wrap(bcc_vals))
      end

    email =
      case d[:reply_to] || d["reply_to"] do
        nil -> email
        rt -> put_header(email, "Reply-To", rt)
      end

    case d[:headers] || d["headers"] do
      nil -> email
      headers -> Enum.reduce(headers, email, fn {k, v}, acc -> put_header(acc, to_string(k), v) end)
    end
  end

  @default_from {"VcfNotifier", "no-reply@localhost"}
  @default_subject "Notification"

  defp default_from, do: Application.get_env(:vcf_notifier, :default_from, @default_from)
  defp default_subject, do: Application.get_env(:vcf_notifier, :default_subject, @default_subject)
end
