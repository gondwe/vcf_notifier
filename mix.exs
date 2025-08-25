defmodule VcfNotifier.MixProject do
  @moduledoc """
  Mix project for VcfNotifier, a flexible notification library for Elixir applications.
  """
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/gondwe/vcf_notifier"

  def project do
    [
      app: :vcf_notifier,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
  mod: {VcfNotifier.Application, []},
  extra_applications: [:logger, :ecto_sql]
    ]
  end

  defp description do
    "A simple notification queuing library for Elixir applications using Oban."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Background job processing
      {:oban, "~> 2.19"},

      # JSON encoding
      {:jason, "~> 1.4"},

      # Database (required for Oban)
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},

      # Email delivery
      {:bamboo, "~> 2.3.1"},
      {:bamboo_phoenix, "~> 1.0"},

      # Development and testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      maintainers: ["Value Chain Factory"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
