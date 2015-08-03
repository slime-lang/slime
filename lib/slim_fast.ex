defmodule SlimFast do
  import SlimFast.Parser
  import SlimFast.Renderer
  import SlimFast.Tree

  require EEx

  def evaluate(input, binding \\ []) do
    input
    |> tokenize
    |> parse_lines
    |> build_tree
    |> render
    |> eval(binding)
  end

  defp eval(html, []), do: html
  defp eval(html, binding) do
    html |> EEx.eval_string(binding)
  end

  defp tokenize(input, delim \\ "\n") do
    String.split(input, delim)
  end
end
