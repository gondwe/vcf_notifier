import Config

# Database configuration for tests (expects local Postgres running)
config :vcf_notifier, VcfNotifier.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  database: System.get_env("PGDATABASE", "vcf_notifier_test"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

# Test environment configuration
config :vcf_notifier, Oban,
  testing: :manual,
  queues: false

# Configure test email provider
config :vcf_notifier,
  email_provider: :test


config :vcf_notifier, :email_opts,
  sender_name: "John Doe",
  sender_email: "test@localhost.com",
  subject: "Test Subject",
  message: "How high are you?"

# Configure Bamboo for testing
config :vcf_notifier, VcfNotifier.Mailer,
  adapter: Bamboo.LocalAdapter
