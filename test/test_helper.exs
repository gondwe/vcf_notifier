ExUnit.start()

# Configure test mode for email provider
Application.put_env(:vcf_notifier, :email_provider, :test)

defmodule SendGridTestAdapter do
  @moduledoc false
  @behaviour Bamboo.Adapter

  def deliver(email, _config), do: {:ok, email}
  def handle_config(config), do: config
  def supports_attachments?, do: true
end

Application.put_env(:vcf_notifier, VcfNotifier.Mailer,
  adapter: SendGridTestAdapter,
  deliver_later_strategy: Bamboo.TaskSupervisorStrategy
)
