defmodule VcfNotifier.Backends.BambooBackend do
  @moduledoc """
  Bamboo email backend implementation.
  """
  import Bamboo.Email

  alias Bamboo.Mailer

  def build_email(data, config) do
    to_value = data["to"] || raise ArgumentError, "missing :to"
    from_value = data["from"] || config["from"] || raise ArgumentError, "missing :from"
    subject_value = data["subject"] || config["subject"] || raise ArgumentError, "missing :subject"

    email =
      new_email()
      |> to(List.wrap(to_value))
      |> from(from_value)
      |> subject(subject_value)

    email =
      case data[:text_body] || data["text_body"] do
        nil -> email
        txt -> text_body(email, txt)
      end

    email =
      case data[:html_body] || data["html_body"] do
        nil -> email
        html -> html_body(email, html)
      end

    email =
      case data[:cc] || data["cc"] do
        nil -> email
        cc_vals -> cc(email, List.wrap(cc_vals))
      end

    email =
      case data[:bcc] || data["bcc"] do
        nil -> email
        bcc_vals -> bcc(email, List.wrap(bcc_vals))
      end

    email =
      case data[:reply_to] || data["reply_to"] do
        nil -> email
        rt -> put_header(email, "Reply-To", rt)
      end

    case data[:headers] || data["headers"] do
      nil ->
        email

      headers ->
        Enum.reduce(headers, email, fn {k, v}, acc -> put_header(acc, to_string(k), v) end)
    end
  end

  def deliver_email(email, opts) do
    Mailer.deliver_now(email, opts)
  end

  # defp get_default_from(config) do
  #   config[:default_from] || config["default_from"] ||
  #     Application.get_env(:vcf_notifier, :default_from, {"VcfNotifier", "no-reply@localhost"})
  # end

  # defp get_default_subject(config) do
  #   config[:default_subject] || config["default_subject"] ||
  #     Application.get_env(:vcf_notifier, :default_subject, "Notification")
  # end

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote location: :keep, bind_quoted: [otp_app: otp_app] do
      use Bamboo.Mailer, otp_app: otp_app
      import Bamboo.Email
      alias VcfNotifier.Backends.BambooBackend

      def build_email(data, config), do: BambooBackend.build_email(data, config)
      def deliver_email(email), do: deliver_now(email)

      defoverridable build_email: 2, deliver_email: 1
    end
  end
end
