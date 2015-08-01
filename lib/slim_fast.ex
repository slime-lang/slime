defmodule SlimFast do
  import SlimFast.Parser
  import SlimFast.Tree

  def evaluate(input) do
    input
    |> tokenize
    |> parse_lines
    |> build_tree
  end

  defp tokenize(input, delim \\ "\n") do
    String.split(input, delim)
  end
end
