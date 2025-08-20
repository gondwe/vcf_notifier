defmodule VcfNotifier.Email.ConfigTest do
  use ExUnit.Case, async: true

  alias VcfNotifier.Email.Config

  describe "validate_config/2" do
    test "validates SMTP configuration" do
      valid_config = %{
        host: "smtp.example.com",
        port: 587,
        username: "user@example.com",
        password: "password"
      }

      assert :ok = Config.validate_config(:smtp, valid_config)
    end

    test "rejects incomplete SMTP configuration" do
      invalid_config = %{
        host: "smtp.example.com",
        port: 587
        # missing username and password
      }

      assert {:error, message} = Config.validate_config(:smtp, invalid_config)
      assert message =~ "Missing required configuration keys"
      assert message =~ "username"
      assert message =~ "password"
    end

    test "validates SendGrid configuration" do
      valid_config = %{api_key: "sg.api_key"}
      assert :ok = Config.validate_config(:sendgrid, valid_config)

      invalid_config = %{}
      assert {:error, message} = Config.validate_config(:sendgrid, invalid_config)
      assert message =~ "api_key"
    end

    test "validates Mailgun configuration" do
      valid_config = %{
        api_key: "mg_api_key",
        domain: "example.com"
      }
      assert :ok = Config.validate_config(:mailgun, valid_config)

      invalid_config = %{api_key: "mg_api_key"}
      assert {:error, message} = Config.validate_config(:mailgun, invalid_config)
      assert message =~ "domain"
    end

    test "validates Postmark configuration" do
      valid_config = %{api_key: "postmark_api_key"}
      assert :ok = Config.validate_config(:postmark, valid_config)
    end

    test "validates SES configuration" do
      valid_config = %{
        access_key: "aws_access_key",
        secret_key: "aws_secret_key",
        region: "us-east-1"
      }
      assert :ok = Config.validate_config(:ses, valid_config)

      invalid_config = %{access_key: "key"}
      assert {:error, message} = Config.validate_config(:ses, invalid_config)
      assert message =~ "secret_key"
      assert message =~ "region"
    end

    test "rejects unsupported provider" do
      assert {:error, "Unsupported email provider: :unknown"} =
        Config.validate_config(:unknown, %{})
    end
  end
end
