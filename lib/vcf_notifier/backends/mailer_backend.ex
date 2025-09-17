defmodule VcfNotifier.Backends.MailBackend do
  @moduledoc """
  Provides a unified `use VcfNotifier.MailBackend, adapter: ...` macro that can wrap either
  Bamboo or Swoosh for delivery. Default is Bamboo.

  Example:

      defmodule MyApp.Mailer do
        use VcfNotifier.MailBackend, otp_app: :my_app, adapter: Bamboo.LocalAdapter
      end

  Or with Swoosh (if `:swoosh` dependency present):

      defmodule MyApp.Mailer do
        use VcfNotifier.MailBackend, otp_app: :my_app, adapter: Swoosh.Adapters.Local, backend: :swoosh
      end

  Options:
    * `:otp_app`  - required, forwarded to underlying mailer
    * `:adapter`  - required for both Bamboo and Swoosh
    * `:backend`  - `:bamboo` (default) | `:swoosh`

  Runtime delivery selection happens via the generated `send/2` function.
  The worker calls `Mailer.send/2` which delegates accordingly.
  """

  defmacro __using__(opts) do
    backend = Keyword.get(opts, :backend, :bamboo)
    otp_app = Keyword.fetch!(opts, :otp_app)
    adapter = Keyword.fetch!(opts, :adapter)

    quote location: :keep, bind_quoted: [backend: backend, otp_app: otp_app, adapter: adapter] do
      @backend backend
      @adapter adapter
      @default_from {"VcfNotifier", "no-reply@localhost"}
      @default_subject "Notification"

      case backend do
        :bamboo ->
          use VcfNotifier.Backends.BambooBackend, otp_app: otp_app
        :swoosh ->
          use VcfNotifier.Backends.SwooshBackend, otp_app: otp_app
        other ->
          raise ArgumentError, "Unsupported backend: #{inspect(other)}"
      end

      def send(%{} = email_map, cfg) when map_size(email_map) > 0 do
        _delivered = email_map |> build_email(cfg) |> deliver_email()
        :ok
      end
      def send(other, _), do: {:error, other}
      defp default_from, do: Application.get_env(:vcf_notifier, :default_from, @default_from)
      defp default_subject, do: Application.get_env(:vcf_notifier, :default_subject, @default_subject)
    end
  end
end
