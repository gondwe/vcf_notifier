defmodule VcfNotifier.Backends.BambooBackend do
  @moduledoc """
  Bamboo email backend implementation.
  """

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote location: :keep, bind_quoted: [otp_app: otp_app] do
      unless Code.ensure_loaded?(Bamboo.Mailer), do: raise "Bamboo not available – add {:bamboo, \"~> 2.3\"}"
      use Bamboo.Mailer, otp_app: otp_app
      import Bamboo.Email

      defp build_email(d, cfg) do
        to_value = d[:to] || d["to"] || raise ArgumentError, "missing :to"
        from_value = d[:from] || d["from"] || cfg[:default_from] || cfg["default_from"] || default_from()
        subject_value = d[:subject] || d["subject"] || cfg[:default_subject] || cfg["default_subject"] || default_subject()
        email = new_email() |> to(List.wrap(to_value)) |> from(from_value) |> subject(subject_value)
        email = case d[:text_body] || d["text_body"] do nil -> email; txt -> text_body(email, txt) end
        email = case d[:html_body] || d["html_body"] do nil -> email; html -> html_body(email, html) end
        email = case d[:cc] || d["cc"] do nil -> email; cc_vals -> cc(email, List.wrap(cc_vals)) end
        email = case d[:bcc] || d["bcc"] do nil -> email; bcc_vals -> bcc(email, List.wrap(bcc_vals)) end
        email = case d[:reply_to] || d["reply_to"] do nil -> email; rt -> put_header(email, "Reply-To", rt) end
        case d[:headers] || d["headers"] do nil -> email; headers -> Enum.reduce(headers, email, fn {k,v}, acc -> put_header(acc, to_string(k), v) end) end
      end

      defp deliver_email(email) do
        deliver_now(email)
      end
    end
  end
end
