defmodule VcfNotifier.MixProject do
  @moduledoc """
  Mix project for VcfNotifier, a flexible notification library for Elixir applications.
  """
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/gondwe/vcf_notifier"

  def project do
    [
      app: :vcf_notifier,
      version: "0.1.1",
      elixir: "~> 1.1",
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
      extra_applications: [:logger],
      mod: {VcfNotifier.Application, []}
    ]
  end

  defp description do
    "A flexible notification library for Elixir applications supporting multiple notification channels."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Email functionality
      {:swoosh, "~> 1.14"},
      {:finch, "~> 0.16"},
      {:jason, "~> 1.4"},

      # Background job processing
      {:oban, "~> 2.15"},

      # Database (required for Oban)
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},

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
