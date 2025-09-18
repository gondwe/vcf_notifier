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
    default_from = Keyword.get(opts, :default_from, {"VcfNotifier", "no-reply@localhost"})
    default_subject = Keyword.get(opts, :default_subject, "Notification")

    alias VcfNotifier.Backends.BambooBackend
    alias VcfNotifier.Backends.SwooshBackend

    quote location: :keep,
          bind_quoted: [
            backend: backend,
            otp_app: otp_app,
            adapter: adapter,
            default_from: default_from,
            default_subject: default_subject
          ] do
      @backend backend
      @adapter adapter
      @default_from default_from
      @default_subject default_subject

      case backend do
        :bamboo -> use BambooBackend, otp_app: otp_app
        :swoosh -> use SwooshBackend, otp_app: otp_app
        other -> raise ArgumentError, "Unsupported backend: #{inspect(other)}"
      end

      @spec send(map(), keyword() | map()) :: :ok | {:error, any()}
      def send(%{} = data, [_ | _] = cfg) do
        %{"email" => data, "config" => Map.new(cfg)}
        |> VcfNotifier.Workers.EmailWorker.new()
        |> Oban.insert()
      end

      def send(_other, _), do: {:error, "Invalid notification payload"}

      # defp default_from, do: Application.get_env(:vcf_notifier, :default_from, @default_from)

      # defp default_subject,
      #   do: Application.get_env(:vcf_notifier, :default_subject, @default_subject)
    end
  end

  # # Module-level functions for when called directly from worker
  # def build_email(email_data, config) do
  #   backend = determine_backend_from_config(config)
  #   backend.build_email(email_data, config)
  # end

  # def deliver_email(email) do
  #   # Determine which backend should handle this email
  #   config = Application.get_env(:vcf_notifier, :config, %{})
  #   backend = determine_backend_from_config(config)
  #   backend.deliver_email(email)
  # end

  # defp determine_backend_from_config(config) do
  #   # First check for explicit backend configuration
  #   backend =
  #     config[:backend] || config["backend"] ||
  #       Application.get_env(:vcf_notifier, :backend)

  #   case backend do
  #     :bamboo ->
  #       VcfNotifier.Backends.BambooBackend

  #     :swoosh ->
  #       VcfNotifier.Backends.SwooshBackend

  #     other ->
  #       raise ArgumentError, "Unsupported backend: #{inspect(other)}. Expected :bamboo or :swoosh"
  #   end
  # end
end
