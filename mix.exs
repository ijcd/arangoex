defmodule Arango.Mixfile do
  use Mix.Project

  def project do
    [app: :Arango,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     # Docs
     # name: "MyApp",
     source_url: "https://github.com/ijcd/Arango",
     # homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
     # docs: [main: "MyApp", # The main page in the docs
     #        logo: "path/to/logo.png",
     #        extras: ["README.md"]]]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger, :inets]]
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
      {:tesla, "~> 0.7.1"},
      {:poison, ">= 1.0.0"},
      # {:ibrowse, "~> 4.4", only: [:dev, :test]},
      # {:hackney, "~> 1.8", only: [:dev, :test]},
      {:exconstructor, "~> 1.0.2"},
      {:faker, "> 0.0.0", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
    ]
  end
end
