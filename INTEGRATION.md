# VcfNotifier Integration Guide

Minimal steps for the slim API.

## 1. Dependency

```elixir
# mix.exs
def deps do
  [
    {:vcf_notifier, "~> 0.1.1"}
  ]
end
```

## 2. (Optional) Defaults

Configure fallback values for missing `:from` and `:subject`. `:to` must be present.

```elixir
# config/runtime.exs or config/config.exs
config :vcf_notifier,
  default_from: {"MyApp", "no-reply@myapp.com"},
  default_subject: "Notification"
```

If omitted, internal defaults are `{ "VcfNotifier", "no-reply@localhost" }` and `"Notification"`.

## 3. Oban Worker (background delivery)

Use the provided worker directly; you enqueue jobs yourself:

```elixir
email_map = %{
  to: "user@example.com",
  text_body: "Hello world"
}

job =
  %{email: email_map}
  |> VcfNotifier.Workers.EmailWorker.new()
  |> Oban.insert!()
```

Configure and start Oban:

```elixir
# config/config.exs
config :my_app, Oban,
  repo: MyApp.Repo,
  queues: [emails: 10]

# application.ex
children = [
  MyApp.Repo,
  {Oban, Application.fetch_env!(:my_app, Oban)}
]
```

## 4. Direct (synchronous) delivery

```elixir
VcfNotifier.Mailer.deliver_email(%{to: "user@example.com", text_body: "Hi"})
```

Raises if `:to` missing; applies fallbacks for `:from` & `:subject`.

## 5. Phoenix / Context Example

```elixir
defmodule MyApp.Accounts do
  alias VcfNotifier.Workers.EmailWorker

  def send_welcome_email(user) do
    email = %{
      to: user.email,
      html_body: MyAppWeb.EmailView.render("welcome.html", user: user)
    }

    email
    |> then(&%{email: &1})
    |> EmailWorker.new()
    |> Oban.insert()
  end
end
```

## Notes

* No validation/serialization in library.
* Provide headers via `:headers` map.
* Extend for CC/BCC/attachments in your app as needed.
* Error handling stays in your code (missing `:to` raises).

Library intentionally minimal.
