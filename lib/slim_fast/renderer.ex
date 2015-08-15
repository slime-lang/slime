defmodule SlimFast.Renderer do
  import SlimFast.Parser
  import SlimFast.Compiler
  import SlimFast.Tree

  @doc """
  Compile slim template to valid EEx HTML.

  ## Examples
      iex> SlimFast.Renderer.precompile("input.required type=val")
      "<input class=\\"required\\" type=\\"<%=val%>\\">"
  """
  def precompile(input) do
    input
    |> tokenize
    |> parse_lines
    |> build_tree
    |> compile
  end

  @doc """
  Evaluate HTML with EEx using the provided bindings.

  ## Examples
      iex> SlimFast.Renderer.eval("<span><%= val %></span>", val: 4)
      "<span>4</span>"
  """
  def eval(html, binding) do
    html |> EEx.eval_string(binding)
  end

  @doc """
  Split the input on the deliminator, defaults to newlines.

  ## Examples
      iex> SlimFast.Renderer.tokenize("div\\nspan")
      ["div", "span"]
  """
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

      @doc """
      Render slim markup and bindings as HTML.

      ## Examples
          iex> defmodule RenderExample do
          ...>   use SlimFast.Renderer
          ...> end
          iex> RenderExample.render("input.required type=val", val: "text")
          "<input class=\\"required\\" type=\\"text\\">"
      """
      def render(slim, args \\ []) do
        slim
        |> precompile
        |> eval(args)
      end
    end
  end
end
