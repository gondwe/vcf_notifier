defmodule VcfNotifierTest do
  use ExUnit.Case
  doctest VcfNotifier

  setup do
    # Ensure test mode for email delivery
    Application.put_env(:vcf_notifier, :email_provider, :test)
    :ok
  end

  describe "Email struct" do
    test "struct can be instantiated" do
      assert %VcfNotifier.Email{to: "a"}.to == "a"
    end
  end

  describe "version/0" do
    test "returns version string" do
      assert is_binary(VcfNotifier.version())
    end
  end
end
