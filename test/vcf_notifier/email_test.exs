defmodule VcfNotifier.EmailTest do
  use ExUnit.Case, async: true

  alias VcfNotifier.{Email, Notification}

  describe "from_notification/1" do
    test "creates email from valid email notification" do
      notification = %Notification{
        type: :email,
        to: "test@example.com",
        subject: "Test Subject",
        body: "Test body",
        metadata: %{
          html_body: "<p>Test body</p>",
          cc: ["cc@example.com"],
          from: "sender@example.com"
        }
      }

      assert {:ok, %Email{} = email} = Email.from_notification(notification)
      assert email.to == ["test@example.com"]
      assert email.subject == "Test Subject"
      assert email.text_body == "Test body"
      assert email.html_body == "<p>Test body</p>"
      assert email.cc == ["cc@example.com"]
      assert email.from == "sender@example.com"
    end

    test "handles multiple recipients" do
      notification = %Notification{
        type: :email,
        to: ["test1@example.com", "test2@example.com"],
        subject: "Test Subject",
        body: "Test body",
        metadata: %{}
      }

      assert {:ok, %Email{} = email} = Email.from_notification(notification)
      assert email.to == ["test1@example.com", "test2@example.com"]
    end

    test "uses default from address when not specified" do
      notification = %Notification{
        type: :email,
        to: "test@example.com",
        subject: "Test Subject",
        body: "Test body",
        metadata: %{}
      }

      assert {:ok, %Email{} = email} = Email.from_notification(notification)
      assert email.from == "noreply@example.com"  # from config
    end

    test "returns error for non-email notification" do
      notification = %Notification{
        type: :sms,
        to: "+1234567890",
        body: "Test message"
      }

      assert {:error, "Expected email notification, got: sms"} =
        Email.from_notification(notification)
    end
  end

  describe "validate_email/1" do
    test "validates required fields" do
      email = %Email{
        to: ["test@example.com"],
        from: "sender@example.com",
        subject: "Test",
        text_body: "Test body"
      }

      assert :ok = Email.validate_email(email)
    end

    test "requires to field" do
      email = %Email{
        to: [],
        from: "sender@example.com",
        subject: "Test",
        text_body: "Test body"
      }

      assert {:error, "Email must have at least one recipient"} =
        Email.validate_email(email)
    end

    test "requires from field" do
      email = %Email{
        to: ["test@example.com"],
        from: nil,
        subject: "Test",
        text_body: "Test body"
      }

      assert {:error, "Email must have a from address"} =
        Email.validate_email(email)
    end

    test "requires subject field" do
      email = %Email{
        to: ["test@example.com"],
        from: "sender@example.com",
        subject: nil,
        text_body: "Test body"
      }

      assert {:error, "Email must have a subject"} =
        Email.validate_email(email)
    end

    test "requires either text or html body" do
      email = %Email{
        to: ["test@example.com"],
        from: "sender@example.com",
        subject: "Test",
        text_body: nil,
        html_body: nil
      }

      assert {:error, "Email must have either text_body or html_body"} =
        Email.validate_email(email)
    end

    test "accepts html body without text body" do
      email = %Email{
        to: ["test@example.com"],
        from: "sender@example.com",
        subject: "Test",
        text_body: nil,
        html_body: "<p>Test body</p>"
      }

      assert :ok = Email.validate_email(email)
    end
  end

  describe "to_swoosh_email/1" do
    test "converts to Swoosh.Email struct" do
      email = %Email{
        to: ["test@example.com"],
        from: "sender@example.com",
        subject: "Test Subject",
        text_body: "Test body",
        html_body: "<p>Test body</p>",
        cc: ["cc@example.com"],
        reply_to: "reply@example.com",
        headers: %{"X-Custom" => "custom-value"}
      }

      swoosh_email = Email.to_swoosh_email(email)

      # Swoosh creates tuples for email addresses: {name, email}
      assert swoosh_email.to == [{"", "test@example.com"}]
      assert swoosh_email.from == {"", "sender@example.com"}
      assert swoosh_email.subject == "Test Subject"
      assert swoosh_email.text_body == "Test body"
      assert swoosh_email.html_body == "<p>Test body</p>"
      assert swoosh_email.cc == [{"", "cc@example.com"}]
      assert swoosh_email.reply_to == {"", "reply@example.com"}
      assert swoosh_email.headers["X-Custom"] == "custom-value"
    end
  end
end
