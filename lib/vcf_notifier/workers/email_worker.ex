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

  alias VcfNotifier.Backends.BambooBackend
  alias VcfNotifier.Backends.SwooshBackend

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.info("Processing queued email")

    %{"email" => %{} = data, "config" => opts} = args

    opts = resolve_key(opts, "default_from", "from")
    opts = set_adapter(opts)
    backend = fetch_backend(opts)

    data
    |> backend.build_email(opts)
    |> backend.deliver_email(atomize_opts(opts))
  end

  def perform(_), do: :discard

  defp fetch_backend(config) do
    case config["backend"] do
      "bamboo" -> BambooBackend
      "swoosh" -> SwooshBackend
      other -> raise ArgumentError, "Unsupported backend: #{inspect(other)}"
    end
  end

  defp resolve_key(opts, key, value) do
    case opts[key] do
      %{"name" => name, "email" => email} ->
        Map.put(opts, value, {name, email})

      _ ->
        opts
    end
  end

  defp set_adapter(opts) do
    case opts["adapter"] do
      a when is_binary(a) -> Map.put(opts, "adapter", String.to_existing_atom(a))
      _ -> opts
    end
  end

  defp atomize_opts(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> Enum.into(%{})
    |> Keyword.new()
  end
end
