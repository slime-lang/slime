defmodule SlimFast.Mixfile do
  use Mix.Project

  def project do
    [app: :slim_fast,
     version: "0.2.0",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: [],
     description: """
     An Elixir library for rendering slim templates.
     """,
     package: [
       files: ["lib", "mix.exs", "README*", "LICENSE*"],
       contributors: ["Sean Callan"],
       licenses: ["MIT"],
       links: %{ "Github" => "https://github.com/doomspork/slim_fast" }
     ]]
  end
end
