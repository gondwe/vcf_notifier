import Config

config :vcf_notifier,
  ecto_repos: [VcfNotifier.Repo]

# Default Repo config (override in runtime or env specific files)
config :vcf_notifier, VcfNotifier.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "vcf_notifier_dev",
  pool_size: 10

# Optional Oban config example (apps can override or disable)
# config :vcf_notifier, Oban,
#   repo: VcfNotifier.Repo,
#   queues: [emails: 10]

# Default configuration for VcfNotifier library
# This provides sensible defaults when the library is used standalone

# For standalone testing without a configured repo
config :vcf_notifier,
  email_provider: :test

# Basic Oban configuration with in-memory repo for testing
# In production, users should configure their own repo
config :vcf_notifier, Oban,
  repo: VcfNotifier.Repo,
  engine: Oban.Engines.Basic,
  queues: [
    auto_approvals: 10,
    stats: 2,
    emails: 5,
    ta_expiry_job: 5,
    payment_notifications: 5
  ]

import_config "#{config_env()}.exs"
