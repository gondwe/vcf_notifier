defmodule VcfNotifier.Email.FlexibleService do
  @moduledoc """
  Simplified email service that focuses on delivery, not content generation.

  This approach lets applications handle their own email building logic
  while the library focuses on reliable delivery and queue management.
  """

  require Logger
  alias VcfNotifier.Email
  alias VcfNotifier.Email.Provider
  alias VcfNotifier.Workers.EmailWorker

  @doc """
  Sends a pre-built email struct immediately.

  ## Example

      # Application builds the email however it wants
      email = %VcfNotifier.Email{
        to: ["user@example.com"],
        from: "noreply@myapp.com",
        subject: "Welcome!",
        html_body: MyApp.EmailTemplates.render("welcome", user: user),
        attachments: [MyApp.PDFGenerator.create_invoice(order)]
      }

      # Library handles delivery
      VcfNotifier.Email.FlexibleService.send_now(email)
  """
  def send_now(%Email{} = email) do
    Logger.info("Sending email to #{inspect(email.to)}")
    Provider.send_email(email)
  end

  @doc """
  Queues a pre-built email for background delivery.
  """
  def send_async(%Email{} = email, opts \\ []) do
    # Convert email struct to notification for worker compatibility
    notification = email_to_notification(email)
    EmailWorker.enqueue(notification, opts)
  end

  @doc """
  Sends emails using application-provided builder function.

  This gives apps full control over email building while still
  using the library's delivery infrastructure.

  ## Example

      # Application provides a builder function
      builder = fn params ->
        user = MyApp.Accounts.get_user!(params[:user_id])
        %VcfNotifier.Email{
          to: [user.email],
          from: "welcome@myapp.com",
          subject: "Welcome " <> user.name <> "!",
          html_body: MyApp.EmailTemplates.render("welcome", user: user)
        }
      end

      # Library handles queuing and delivery
      VcfNotifier.Email.FlexibleService.send_with_builder(
        builder,
        %{user_id: 123}
      )
  """
  def send_with_builder(builder_fun, params, opts \\ []) when is_function(builder_fun, 1) do
    case builder_fun.(params) do
      %Email{} = email ->
        send_async(email, opts)
      {:ok, %Email{} = email} ->
        send_async(email, opts)
      {:error, _} = error ->
        error
      other ->
        {:error, "Builder function must return %VcfNotifier.Email{} or {:ok, email}, got: #{inspect(other)}"}
    end
  end

  @doc """
  Bulk send with application-provided builder.
  """
  def send_bulk_with_builder(builder_fun, params_list, opts \\ []) when is_function(builder_fun, 1) and is_list(params_list) do
    results =
      params_list
      |> Enum.map(fn params ->
        case builder_fun.(params) do
          %Email{} = email -> send_async(email, opts)
          {:ok, %Email{} = email} -> send_async(email, opts)
          error -> error
        end
      end)

    # Separate successes from failures
    {successes, failures} = Enum.split_with(results, &match?({:ok, _}, &1))

    if length(failures) > 0 do
      Logger.warning("#{length(failures)} emails failed to queue: #{inspect(failures)}")
    end

    {:ok, %{
      queued: length(successes),
      failed: length(failures),
      jobs: Enum.map(successes, fn {:ok, job} -> job end),
      errors: failures
    }}
  end

  # Private helper to convert email struct to notification for worker compatibility
  defp email_to_notification(%Email{} = email) do
    %VcfNotifier.Notification{
      type: :email,
      to: List.first(email.to) || "",
      subject: email.subject,
      body: email.text_body || email.html_body || "",
      metadata: %{
        from: email.from,
        cc: email.cc,
        bcc: email.bcc,
        html_body: email.html_body,
        attachments: email.attachments,
        headers: email.headers,
        provider_options: email.provider_options
      },
      status: :pending
    }
  end
end
