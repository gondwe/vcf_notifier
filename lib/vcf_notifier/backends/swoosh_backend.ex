defmodule VcfNotifier.Backends.SwooshBackend do
  @moduledoc """
  Swoosh email backend implementation.
  """
  import Swoosh.Email

  alias Swoosh.Mailer

  @data_keys ~w(to from subject text_body html_body cc bcc reply_to headers message)

  def build_email(data, config) do
    to_value = data["to"] || raise ArgumentError, "missing :to"
    from_value = config["from"] || raise ArgumentError, "missing :from"

    subject_value =
      data["subject"] || config["subject"] || raise ArgumentError, "missing :subject"

    email =
      new()
      |> to(to_value)
      |> from(from_value)
      |> subject(subject_value)

    email =
      Enum.reduce(@data_keys, email, fn key, acc ->
        case data[key] || data[String.to_existing_atom(key)] do
          nil ->
            acc

          value ->
            case key do
              "text_body" -> text_body(acc, value)
              "html_body" -> html_body(acc, value)
              "cc" -> cc(acc, List.wrap(value))
              "bcc" -> bcc(acc, List.wrap(value))
              "reply_to" -> reply_to(acc, value)
              "message" -> text_body(acc, value)
              _ -> acc
            end
        end
      end)

    case data[:headers] || data["headers"] do
      nil -> email
      headers -> Enum.reduce(headers, email, fn {k, v}, acc -> header(acc, to_string(k), v) end)
    end
  end

  def deliver_email(email, opts) do
    Mailer.deliver(email, opts)
  end

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote location: :keep, bind_quoted: [otp_app: otp_app] do
      use Swoosh.Mailer, otp_app: otp_app
      import Swoosh.Email

      alias VcfNotifier.Backends.SwooshBackend

      def build_email(data, config), do: SwooshBackend.build_email(data, config)
      def deliver_email(email), do: deliver(email)

      defoverridable build_email: 2, deliver_email: 1
    end
  end
end
