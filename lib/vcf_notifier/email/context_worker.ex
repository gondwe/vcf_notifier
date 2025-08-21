defmodule VcfNotifier.Email.ContextWorker do
  @moduledoc """
  Enhanced Oban worker for processing context-based email jobs.

  This worker can handle different types of emails by delegating to
  specific mailer modules that implement the VcfNotifier.Email.Generator behaviour.
  """

  use Oban.Worker,
    queue: :emails,
    max_attempts: 3

  require Logger
  alias VcfNotifier.Email.Service

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"ctx" => ctx_module} = args}) do
    args
    |> build_and_send_email(ctx_module)
    |> log_result()

    :ok
  end

  def perform(%Oban.Job{args: args}) do
    # Fallback to standard notification processing
    case args do
      %{"notification" => notification_data} ->
        notification = struct(VcfNotifier.Notification, atomize_keys(notification_data))
        Service.send_now(notification)
        :ok
      _ ->
        {:error, "Invalid job args: #{inspect(args)}"}
    end
  end

  @doc """
  Creates a new context-based email job.
  """
  def new_context_job(ctx_module, params, opts \\ []) do
    params
    |> Map.put("ctx", to_string(ctx_module))
    |> then(&%{ctx: to_string(ctx_module), params: &1})
    |> new(opts)
  end

  defp build_and_send_email(%{"ctx" => _ctx_module} = args, ctx_module_name) do
    try do
      module = String.to_existing_atom(ctx_module_name)

      case apply(module, :build_email, [args]) do
        nil ->
          {:error, "Email builder returned nil for #{ctx_module_name}"}
        email_data ->
          send_email_with_data(email_data, module)
      end
    rescue
      ArgumentError ->
        {:error, "Module #{ctx_module_name} does not exist"}
      error ->
        {:error, "Error building email: #{inspect(error)}"}
    end
  end

  defp send_email_with_data(email_data, module) do
    # Get email configuration
    opts = get_email_config()

    # Prepare email with attachments if needed
    email_data = maybe_add_attachments(email_data, module)

    # Build the email struct
    email_struct = build_email_struct(email_data, opts)

    # Send via the email service
    case VcfNotifier.Email.Provider.send_email(email_struct) do
      {:ok, result} ->
        {:ok, %{email: result, data: email_data}}
      error ->
        error
    end
  end

  defp maybe_add_attachments(%{file: _} = email_data, _module), do: email_data
  defp maybe_add_attachments(email_data, module) do
    if function_exported?(module, :prepare_attachments, 1) do
      case apply(module, :prepare_attachments, [email_data]) do
        nil -> email_data
        attachment -> Map.put(email_data, :file, attachment)
      end
    else
      email_data
    end
  end

  defp build_email_struct(email_data, opts) do
    sender_name = Keyword.get(opts, :sender_name, "VcfNotifier")
    sender_email = Keyword.get(opts, :sender_email, "noreply@example.com")
    subject = email_data[:subject] || Keyword.get(opts, :default_subject, "Notification")

    %VcfNotifier.Email{
      to: normalize_recipients(email_data[:email]),
      from: {sender_name, sender_email},
      subject: "#{subject}#{maybe_add_recipient_name(email_data[:name])}",
      text_body: email_data[:text_body] || email_data[:content],
      html_body: email_data[:html_body],
      attachments: maybe_prepare_attachment(email_data[:file]),
      provider_options: Map.get(email_data, :custom_args, %{})
    }
  end

  defp maybe_add_recipient_name(nil), do: ""
  defp maybe_add_recipient_name(name), do: " - #{name}"

  defp normalize_recipients(email) when is_binary(email), do: [email]
  defp normalize_recipients(emails) when is_list(emails), do: emails
  defp normalize_recipients(_), do: []

  defp maybe_prepare_attachment(nil), do: []
  defp maybe_prepare_attachment(file_data) when is_map(file_data) do
    [file_data]
  end
  defp maybe_prepare_attachment(_), do: []

  defp get_email_config do
    Application.get_env(:vcf_notifier, :email_opts, [
      sender_name: "VcfNotifier",
      sender_email: "noreply@example.com",
      default_subject: "Notification"
    ])
  end

  defp log_result({:ok, %{email: email_result, data: email_data}}) do
    Logger.info("Email sent successfully",
      email: email_data[:email],
      subject: email_data[:subject]
    )

    # Here you could integrate with email event tracking
    # similar to the EmailEvent module in your production code
    {:ok, email_result}
  end

  defp log_result({:error, reason}) do
    Logger.error("Failed to send email: #{inspect(reason)}")
    {:error, reason}
  end

  defp atomize_keys(map) when is_map(map) do
    for {key, val} <- map, into: %{} do
      {
        (if is_binary(key), do: String.to_existing_atom(key), else: key),
        atomize_keys(val)
      }
    end
  end

  defp atomize_keys(val), do: val
end
