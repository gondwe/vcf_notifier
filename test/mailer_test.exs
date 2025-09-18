defmodule VcfNotifier.MailerTest do
  use ExUnit.Case
  alias VcfNotifier.Email

  setup do
    Application.put_env(:vcf_notifier, :default_from, {"Test", "test@example.com"})
    :ok
  end

  test "Email.send builds job changeset merging configs when Oban not running" do
    email = %{to: "someone@example.com", subject: "Hi", text_body: "Body"}
    {:ok, %Ecto.Changeset{} = cs} = Email.send(email, custom: 1)
    args = cs.changes.args
    job_email = Map.fetch!(args, :email)
    cfg = Map.fetch!(args, :config)
    assert (job_email[:to] || job_email["to"]) == "someone@example.com"
    assert (cfg[:default_from] || cfg["default_from"]) != nil
    assert (cfg[:custom] || cfg["custom"]) == 1
  end
end
