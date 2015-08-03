defmodule SlimFast do
  import SlimFast.Parser
  import SlimFast.Renderer
  import SlimFast.Tree

  def evaluate(input) do
    input
    |> tokenize
    |> parse_lines
    |> build_tree
    |> render
  end

  def tokenize(input, delim \\ "\n") do
    String.split(input, delim)
  end
end
