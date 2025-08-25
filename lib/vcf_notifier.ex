defmodule VcfNotifier do
  @moduledoc """
  VcfNotifier provides simple email sending functionality.

  Just create an email struct and call `VcfNotifier.Email.send/1`.
  Everything gets queued automatically via Oban and delivered via your configured mailer.

  ## Usage

      email = %VcfNotifier.Email{
        to: "user@example.com",
        from: "noreply@yourapp.com",
        subject: "Hello",
        text_body: "Hello world!"
      }

      VcfNotifier.Email.send(email)

  ## Configuration

  Configure your mailer in config.exs:

      config :vcf_notifier, mailer_module: YourApp.Mailer

  """

  @doc """
  Returns the library version.
  """
  @spec version() :: String.t()
  def version do
    Application.spec(:vcf_notifier, :vsn) |> to_string()
  end
end
