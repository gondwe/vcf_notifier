# VcfNotifier

Minimal email queue helper (Oban + Bamboo).

## Install
```elixir
def deps do
  [ {:vcf_notifier, "~> 0.2"}, {:oban, "~> 2.19"}, {:ecto_sql, "~> 3.10"}, {:postgrex, "~> 0.17"}, {:bamboo, "~> 2.3"} ]
end
```
## Configure
```elixir
config :vcf_notifier,
  default_from: {"YourApp", "no-reply@yourapp.test"},
  default_subject: "Notification"
config :vcf_notifier, VcfNotifier.Mailer, adapter: Bamboo.LocalAdapter
config :vcf_notifier, Oban, repo: YourApp.Repo, queues: [emails: 10]
```
## Send
```elixir
email = %{to: "user@example.com", subject: "Welcome", text_body: "Hi"}
{:ok, res} = VcfNotifier.Email.send(email)
```
Returns job if Oban running else changeset (or error if Oban absent). `:to` required; others fallback.

## Components
Email · Mailer · EmailWorker · Repo(optional)

## Notes
No validation/serialization; build bulk & scheduling with Oban.

## License
MIT
