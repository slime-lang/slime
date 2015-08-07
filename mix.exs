defmodule SlimFast.Mixfile do
  use Mix.Project

  @version "0.4.1"

  def project do
    [app: :slim_fast,
     build_embedded: Mix.env == :prod,
     deps: [],
     description: """
     An Elixir library for rendering slim templates.
     """,
     elixir: "~> 1.0",
     package: package,
     source_url: "https://github.com/doomspork/slim_fast",
     start_permanent: Mix.env == :prod,
     version: @version]
  end

  def package do
    [contributors: ["Sean Callan"],
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/doomspork/slim_fast"}]
  end
end
