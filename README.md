# VcfNotifier

Tiny helper to enqueue and deliver emails with Oban + Bamboo. No validation, no provider logic – just a thin job layer.

## Install
```elixir
def deps do
  [
    {:vcf_notifier, "~> 0.2"},
    {:oban, "~> 2.19"},
    {:ecto_sql, "~> 3.10"}, {:postgrex, "~> 0.17"},
    {:bamboo, "~> 2.3"}
  ]
end
```

## Configure
```elixir
config :vcf_notifier,
  default_from: {"YourApp", "no-reply@yourapp.test"},
  default_subject: "Notification"

config :vcf_notifier, VcfNotifier.Mailer,
  adapter: Bamboo.LocalAdapter

config :vcf_notifier, Oban,
  repo: YourApp.Repo,
  queues: [emails: 10]
```

## Usage
```elixir
{:ok, result} = VcfNotifier.Email.send(%{to: "user@example.com", text_body: "Hi"})
```
If Oban is running, `result` is an inserted `Oban.Job`; otherwise an *uninserted* changeset you can insert later.

Required: `:to`. Optional: `:subject`, `:text_body`, `:html_body`, `:from` (falls back to config), attachments via `:attachments` list (passed through to Bamboo if present).

## Philosophy
Keep this layer minimal; do templating, retries tuning, metrics, or multi‑channel logic in your app.

## License
MIT
