defmodule Arangoex.Mixfile do
  use Mix.Project

  @version "0.0.1"
  @source_url "https://github.com/ijcd/arangoex"
  @description "Low-level driver for ArangoDB"

  def project do
    [
      app: :arango,
      version: @version,
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # docs
      description: @description,
      name: "Arango",
      source_url: @source_url,
      package: package(),
      dialyzer: [flags: "--fullpath"],
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

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "> 0.0.0"},
      {:poison, "> 0.0.0"},
      {:exconstructor, "~> 1.0.2"},
      {:faker, "> 0.0.0", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:credo, "~> 0.4", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      description: @description,
      files: ["lib", "config", "mix.exs", "README*"],
      maintainers: ["Ian Duggan"],
      licenses: ["Apache 2.0"],
      links: %{GitHub: @source_url}
    ]
  end  
end
