import Config

# Default configuration for VcfNotifier library
# This provides sensible defaults when the library is used standalone

# For standalone testing without a configured repo
config :vcf_notifier,
  email_provider: :smtp,
  default_from_email: "noreply@example.com"

# Basic Oban configuration with in-memory repo for testing
# In production, users should configure their own repo
config :vcf_notifier, Oban,
  testing: :manual,
  queues: [
    emails: 10,
    default: 5
  ]

config :vcf_notifier, :email_providers,
  smtp: %{
    host: "localhost",
    port: 1025,
    username: "",
    password: "",
    ssl: false,
    tls: :never,
    auth: :never
  }

# Configure Swoosh for testing
config :swoosh, :api_client, false

import_config "#{config_env()}.exs"
