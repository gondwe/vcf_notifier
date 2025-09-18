defmodule VcfNotifier.Application do
  @moduledoc """
  Application module for VcfNotifier.

  Starts supervision tree with Oban for background job processing.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children =
      [
        VcfNotifier.Repo,
        {Oban, Application.fetch_env!(:vcf_notifier, Oban)}
      ]

    opts = [strategy: :one_for_one, name: VcfNotifier.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("VcfNotifier application started successfully")
        {:ok, pid}

      {:error, reason} = error ->
        Logger.error("Failed to start VcfNotifier application: #{inspect(reason)}")
        error
    end
  end

  # defp oban_children do
  #   case Application.fetch_env(:vcf_notifier, Oban) do
  #     {:ok, oban_config} ->
  #       # Only start Oban if we have a proper configuration
  #       if Keyword.get(oban_config, :testing) == :manual do
  #         # In test mode, don't start Oban
  #         []
  #       else
  #         [{Oban, oban_config}]
  #       end

  #     :error ->
  #       # No Oban configuration found, skip starting Oban
  #       Logger.warning("No Oban configuration found, background jobs will not be available")
  #       []
  #   end
  # end
end
