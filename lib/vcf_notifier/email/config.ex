defmodule VcfNotifier.Email.Config do
  @moduledoc """
  Configuration management for email providers.

  Supports multiple email providers including SMTP, SendGrid, Mailgun, etc.
  """

  @type provider :: :smtp | :sendgrid | :mailgun | :postmark | :ses
  @type config :: %{
    provider: provider(),
    settings: map()
  }

  @doc """
  Gets the configured email provider.
  """
  @spec get_provider() :: provider()
  def get_provider do
    Application.get_env(:vcf_notifier, :email_provider, :smtp)
  end

  @doc """
  Gets the configuration for the specified provider.
  """
  @spec get_config(provider()) :: map()
  def get_config(provider) do
    providers_config = Application.get_env(:vcf_notifier, :email_providers, %{})

    case providers_config do
      config when is_map(config) ->
        Map.get(config, provider, %{})

      config when is_list(config) ->
        # Handle keyword list format
        Keyword.get(config, provider, %{})

      _ ->
        %{}
    end
  end

  @doc """
  Gets the current provider configuration.
  """
  @spec get_current_config() :: map()
  def get_current_config do
    get_config(get_provider())
  end

  @doc """
  Validates the email configuration.
  """
  @spec validate_config(provider(), map()) :: :ok | {:error, String.t()}
  def validate_config(:smtp, config) do
    required_keys = [:host, :port, :username, :password]
    validate_required_keys(config, required_keys)
  end

  def validate_config(:sendgrid, config) do
    required_keys = [:api_key]
    validate_required_keys(config, required_keys)
  end

  def validate_config(:mailgun, config) do
    required_keys = [:api_key, :domain]
    validate_required_keys(config, required_keys)
  end

  def validate_config(:postmark, config) do
    required_keys = [:api_key]
    validate_required_keys(config, required_keys)
  end

  def validate_config(:ses, config) do
    required_keys = [:access_key, :secret_key, :region]
    validate_required_keys(config, required_keys)
  end

  def validate_config(:test, _config) do
    :ok
  end

  def validate_config(provider, _config) do
    {:error, "Unsupported email provider: #{inspect(provider)}"}
  end

  defp validate_required_keys(config, required_keys) do
    missing_keys = required_keys -- Map.keys(config)

    if missing_keys == [] do
      :ok
    else
      {:error, "Missing required configuration keys: #{inspect(missing_keys)}"}
    end
  end
end
