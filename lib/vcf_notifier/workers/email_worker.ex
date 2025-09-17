defmodule VcfNotifier.Workers.EmailWorker do
  @moduledoc """
  Oban worker for processing emails in the background.

  Simple worker that takes an email struct and delivers it.
  """

  use Oban.Worker,
    queue: :emails,
    max_attempts: 3,
    tags: ["email"]

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => %{} = args} = job_args}) when map_size(args) > 0 do
    Logger.info("Processing queued email")

    opts = Map.get(job_args, "config", [])

    mailer_mod =
      cond do
        mod = opts[:mailer_module] -> mod
        mod = opts["mailer_module"] -> mod
        mod = Application.get_env(:vcf_notifier, :mailer_module) -> mod
        true -> VcfNotifier.Mailer
      end

    send_fun = function_exported?(mailer_mod, :send, 2) && &mailer_mod.send/2

    result =
      if send_fun do
        send_fun.(args, opts)
      else
        {:error, :no_mailer_send}
      end

    case result do
      :ok ->
        :ok

      {:error, reason} = err ->
        Logger.error("Email delivery failed: #{inspect(reason)}")
        err
    end
  end

  def perform(_), do: :discard
end
