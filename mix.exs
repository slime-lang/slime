defmodule Slime.Mixfile do
  use Mix.Project

  @version "0.13.0"

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
      # HTML generation helpers
      {:phoenix_html, "~> 2.2", only: :test},
      # Benchmarking tool
      {:benchfella, "~> 0.3", only: ~w(dev test)a},
      # Automatic test runner
      {:mix_test_watch, only: :dev},
      # Style linter
      {:dogma, ">= 0.0.0", only: ~w(dev test)a},
    ]
  end
end
