defmodule Slime.Mixfile do
  use Mix.Project

  @version "0.16.0"

  @compile_peg_task "tasks/compile.peg.exs"
  @do_peg_compile File.exists?(@compile_peg_task)
  if @do_peg_compile do
    Code.eval_file @compile_peg_task
  end

  def project do
    [app: :slime,
     build_embedded: Mix.env == :prod,
     deps: deps(),
     description: """
     An Elixir library for rendering Slim-like templates.
     """,
     elixir: "~> 1.3",
     package: package(),
     source_url: "https://github.com/slime-lang/slime",
     start_permanent: Mix.env == :prod,
     compilers: compilers(Mix.env),
     version: @version]
  end

  defp compilers(_), do: [:peg, :erlang, :elixir, :app]

  def application do
    [
      applications: [:eex]
    ]
  end

  def package do
    [
      maintainers: ["Sean Callan", "Alexander Stanko"],
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/slime-lang/slime"},
    ]
  end

  def deps do
    [
      # packrat parser-generator for PEGs
      {:neotoma, "~> 1.7"},
      # Benchmarking tool
      {:benchfella, ">= 0.0.0", only: ~w(dev test)a},
      # Documentation
      {:ex_doc, ">= 0.0.0", only: :dev},
      # Automatic test runner
      {:mix_test_watch, ">= 0.0.0", only: :dev},
      # Style linter
      {:credo, ">= 0.0.0", only: ~w(dev test)a},
      # HTML generation helpers
      {:phoenix_html, "~> 2.6", only: :test},
    ]
  end
end
