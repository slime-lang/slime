defmodule Slime.Renderer do
  import Slime.Parser
  import Slime.Compiler
  import Slime.Tree

  @doc """
  Compile slim template to valid EEx HTML.

  ## Examples
      iex> Slime.Renderer.precompile(~s(input.required type="hidden"))
      "<input class=\\"required\\" type=\\"hidden\\">"
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
      iex> Slime.Renderer.eval("<span><%= val %></span>", val: 4)
      "<span>4</span>"
  """
  def eval(html, binding) do
    html |> EEx.eval_string(binding)
  end

  @doc """
  Split the input on the deliminator, defaults to newlines.

  ## Examples
      iex> Slime.Renderer.tokenize("div\\nspan")
      ["div", "span"]
  """
  def tokenize(input, delim \\ "\n") do
    String.split(input, delim)
  end

  defmacro __using__([]) do
    quote do
      import unquote __MODULE__
      import Slime.Parser
      import Slime.Compiler
      import Slime.Tree

      require EEx

      @doc """
      Render slim markup and bindings as HTML.

      ## Examples
          iex> defmodule RenderExample do
          ...>   use Slime.Renderer
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
