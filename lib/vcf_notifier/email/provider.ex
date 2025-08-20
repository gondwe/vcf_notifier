defmodule VcfNotifier.Email.Provider do
  @moduledoc """
  Email provider abstraction layer.

  Handles sending emails through different providers using Swoosh.
  """

  alias VcfNotifier.Email
  alias VcfNotifier.Email.Config
  require Logger

  @doc """
  Sends an email using the configured provider.
  """
  @spec send_email(Email.t()) :: {:ok, term()} | {:error, term()}
  def send_email(%Email{} = email) do
    provider = Config.get_provider()
    config = Config.get_current_config()

    Logger.debug("Sending email via #{provider}")

    with :ok <- Config.validate_config(provider, config),
         {:ok, mailer} <- get_mailer(provider, config),
         swoosh_email <- Email.to_swoosh_email(email) do
      send_via_provider(mailer, swoosh_email)
    end
  end

  @doc """
  Gets the appropriate Swoosh mailer for the provider.
  """
  @spec get_mailer(Config.provider(), map()) :: {:ok, module()} | {:error, String.t()}
  def get_mailer(:smtp, config) do
    mailer = {Swoosh.Adapters.SMTP,
      relay: config[:host],
      port: config[:port],
      username: config[:username],
      password: config[:password],
      ssl: Map.get(config, :ssl, false),
      tls: Map.get(config, :tls, :if_available),
      auth: Map.get(config, :auth, :always),
      retries: Map.get(config, :retries, 1)
    }
    {:ok, mailer}
  end

  def get_mailer(:sendgrid, config) do
    mailer = {Swoosh.Adapters.Sendgrid,
      api_key: config[:api_key]
    }
    {:ok, mailer}
  end

  def get_mailer(:mailgun, config) do
    mailer = {Swoosh.Adapters.Mailgun,
      api_key: config[:api_key],
      domain: config[:domain],
      base_url: Map.get(config, :base_url, "https://api.mailgun.net/v3")
    }
    {:ok, mailer}
  end

  def get_mailer(:postmark, config) do
    mailer = {Swoosh.Adapters.Postmark,
      api_key: config[:api_key]
    }
    {:ok, mailer}
  end

  def get_mailer(:ses, config) do
    mailer = {Swoosh.Adapters.AmazonSES,
      access_key: config[:access_key],
      secret: config[:secret_key],
      region: config[:region]
    }
    {:ok, mailer}
  end

  def get_mailer(:test, _config) do
    mailer = {Swoosh.Adapters.Test, []}
    {:ok, mailer}
  end

  def get_mailer(provider, _config) do
    {:error, "Unsupported email provider: #{inspect(provider)}"}
  end

  # Private functions

  defp send_via_provider({adapter, adapter_config}, email) do
    case Swoosh.Mailer.deliver(email, adapter: adapter, config: adapter_config) do
      {:ok, response} ->
        Logger.info("Email sent successfully")
        Logger.debug("Provider response: #{inspect(response)}")
        {:ok, response}

      {:error, reason} = error ->
        Logger.error("Failed to send email: #{inspect(reason)}")
        error
    end
  end
end
