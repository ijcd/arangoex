defmodule Arango.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/ijcd/arangoex"
  @description "Low-level driver for ArangoDB"

  def project do
    [
      app: :arango,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # docs
      description: @description,
      name: "Arango",
      source_url: @source_url,
      package: package(),
      aliases: aliases(),
      dialyzer: [
        plt_local_path: "priv/plts/project.plt",
        plt_core_path: "priv/plts/core.plt",
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        source_url: @source_url,
        extras: [
          "README.md"
        ]
      ]
    ]
  end

  def application do
    [
      mod: {Arango.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.15"},
      {:jason, "~> 1.4"},
      {:finch, "~> 0.19"},
      {:exconstructor, "~> 1.2"},
      {:faker, "~> 0.18", only: :test},
      {:mix_test_watch, "~> 1.0", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: @description,
      files: ["lib", "config", "mix.exs", "README*"],
      maintainers: ["Ian Duggan"],
      licenses: ["Apache-2.0"],
      links: %{GitHub: @source_url}
    ]
  end

  # `mix verify` runs every static gate the CI workflow runs except the
  # integration tests (which require ArangoDB). Useful before pushing.
  defp aliases do
    [
      verify: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo",
        "dialyzer"
      ]
    ]
  end
end
