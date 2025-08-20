import Config

# Test environment configuration
config :vcf_notifier, Oban,
  testing: :manual,
  queues: false

# Use test adapter for Swoosh in tests
config :swoosh, :api_client, false

# Configure test email provider
config :vcf_notifier,
  email_provider: :test

config :vcf_notifier, :email_providers,
  test: %{}
