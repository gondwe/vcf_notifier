defmodule VcfNotifier.Workers.EmailWorkerTest do
  use ExUnit.Case

  alias VcfNotifier.Workers.EmailWorker

  setup do
    # Ensure test mode for email delivery
    Application.put_env(:vcf_notifier, :email_provider, :test)
  Application.put_env(:vcf_notifier, :mailer_module, VcfNotifier.Mailer)
    :ok
  end

  describe "perform/1" do
    test "processes email job successfully" do
      email_data = %{
        "to" => "test@example.com",
        "from" => "sender@example.com",
        "subject" => "Test Subject",
        "text_body" => "Test Body",
        "html_body" => nil,
        "cc" => [],
        "bcc" => [],
        "reply_to" => nil,
        "attachments" => [],
        "headers" => %{},
        "provider_options" => %{}
      }

  job = %Oban.Job{args: %{"email" => email_data, "config" => %{default_subject: "Alt", mailer_module: VcfNotifier.Mailer}}}

      # Should succeed in test mode
      assert :ok = EmailWorker.perform(job) |> dbg()
    end

    test "discards when missing email key" do
      assert :discard = EmailWorker.perform(%Oban.Job{args: %{}})
    end
  end
end
