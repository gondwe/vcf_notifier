defmodule VcfNotifier.Email.Generator do
  @moduledoc """
  Behaviour for email generator modules.

  This behaviour defines the interface that email generators must implement
  to work with the VcfNotifier email system.

  ## Example Implementation

      defmodule MyApp.Emails.WelcomeMailer do
        use VcfNotifier.Email.Generator

        @impl true
        def build_email(params) do
          %{
            subject: "Welcome to MyApp!",
            email: params["email"],
            name: params["name"],
            html_body: "<h1>Welcome " <> params["name"] <> "!</h1>",
            text_body: "Welcome " <> params["name"] <> "!",
            custom_args: %{
              user_id: params["user_id"],
              category: "welcome"
            }
          }
        end

        @impl true
        def prepare_attachments(_params), do: nil
      end
  """

  @doc """
  Builds the email data structure from parameters.

  Should return a map with the following keys:
  - subject: Email subject line
  - email: Recipient email address
  - name: Recipient name
  - html_body: HTML email body (optional)
  - text_body: Plain text email body (optional)
  - custom_args: Map of custom arguments for tracking (optional)
  - file: Attachment data (optional, or use prepare_attachments/1)
  """
  @callback build_email(map()) :: map() | nil

  @doc """
  Prepares attachments for the email.

  Should return attachment data structure or nil if no attachments.
  """
  @callback prepare_attachments(any()) :: map() | nil

  @optional_callbacks [prepare_attachments: 1]

  defmacro __using__(_opts) do
    quote do
      @behaviour VcfNotifier.Email.Generator

      def prepare_attachments(_), do: nil

      defoverridable prepare_attachments: 1
    end
  end
end
