defmodule Slime.Mixfile do
  use Mix.Project

  @version "0.15.0"

  def project do
    [app: :slime,
     build_embedded: Mix.env == :prod,
     deps: deps,
     description: """
     An Elixir library for rendering Slim-like templates.
     """,
     elixir: "~> 1.0",
     package: package,
     source_url: "https://github.com/slime-lang/slime",
     start_permanent: Mix.env == :prod,
     version: @version]
  end

  def application do
    [applications: [:eex]]
  end

  def package do
    [
      maintainers: [
        "Sean Callan", "Alexander Stanko", "Henrik Nyh", "Louis Pilfold",
      ],
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/slime-lang/slime"},
    ]
  end

  def deps do
    [
      # Benchmarking tool
      {:benchfella, "~> 0.3", only: ~w(dev test)a},
      # Documentation
      {:ex_doc, "~> 0.12", only: :dev},
      # Automatic test runner
      {:mix_test_watch, ">= 0.0.0", only: :dev},
      # Style linter
      {:credo, ">= 0.0.0", only: ~w(dev test)a},
      # HTML generation helpers
      {:phoenix_html, "~> 2.2", only: :test},
    ]
  end
end
