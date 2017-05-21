defmodule Arangoex.Mixfile do
  use Mix.Project

  def project do
    [app: :arangoex,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :poison]]
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

      # dev, test
      {:faker, "> 0.0.0", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:credo, "~> 0.4", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev, :test]},
      {:deep_merge, "~> 0.1.0", only: [:dev, :test]},
      {:json_diff_ex, "~> 0.5.0", only: [:dev, :test]},
      {:focus, "~> 0.2.4", only: [:dev, :test]},
    ]
  end
end
