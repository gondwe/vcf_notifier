defmodule VcfNotifier.Email.Examples.WelcomeMailer do
  @moduledoc """
  Example mailer module demonstrating the VcfNotifier.Email.Generator pattern.

  This shows how consuming applications can create their own mailer modules
  for different types of emails with sophisticated business logic.
  """

  use VcfNotifier.Email.Generator

  @impl true
  def build_email(%{"user_id" => nil}), do: nil
  def build_email(%{"user_id" => ""}), do: nil

  def build_email(%{"user_id" => user_id} = params) do
    # In a real application, you might fetch user data from the database here
    user_name = params["name"] || "User"
    user_email = params["email"] || raise "Email is required"

    %{
      subject: "Welcome to VcfNotifier!",
      email: user_email,
      name: user_name,
      html_body: build_html_body(user_name),
      text_body: build_text_body(user_name),
      custom_args: %{
        user_id: user_id,
        category: "welcome",
        template: "welcome"
      }
    }
  end

  @impl true
  def prepare_attachments(%{"include_guide" => true}) do
    %{
      filename: "welcome_guide.pdf",
      data: "PDF content would go here...",
      content_type: "application/pdf"
    }
  end

  def prepare_attachments(_params), do: nil

  # Private helper functions
  defp build_html_body(name) do
    """
    <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; }
          .header { background-color: #f0f8ff; padding: 20px; }
          .content { padding: 20px; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Welcome to VcfNotifier!</h1>
        </div>
        <div class="content">
          <p>Hello #{name},</p>
          <p>Thank you for joining VcfNotifier. We're excited to help you send notifications efficiently!</p>
          <p>
            <strong>Getting Started:</strong><br>
            • Configure your email providers<br>
            • Create your first notification<br>
            • Monitor delivery status
          </p>
          <p>Best regards,<br>The VcfNotifier Team</p>
        </div>
      </body>
    </html>
    """
  end

  defp build_text_body(name) do
    """
    Welcome to VcfNotifier!

    Hello #{name},

    Thank you for joining VcfNotifier. We're excited to help you send notifications efficiently!

    Getting Started:
    • Configure your email providers
    • Create your first notification
    • Monitor delivery status

    Best regards,
    The VcfNotifier Team
    """
  end
end
