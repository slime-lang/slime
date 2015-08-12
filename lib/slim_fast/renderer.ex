defmodule SlimFast.Renderer do
  import SlimFast.Parser
  import SlimFast.Compiler
  import SlimFast.Tree

  def precompile(input) do
    input
    |> tokenize
    |> parse_lines
    |> build_tree
    |> compile
  end

  def eval(html, binding) do
    html |> EEx.eval_string(binding)
  end

  def tokenize(input, delim \\ "\n") do
    String.split(input, delim)
  end

  defmacro __using__([]) do
    quote do
      import unquote __MODULE__
      import SlimFast.Parser
      import SlimFast.Compiler
      import SlimFast.Tree

      require EEx

      def render(slim, args \\ []) do
        slim
        |> precompile
        |> eval(args)
      end
    end
  end
end
