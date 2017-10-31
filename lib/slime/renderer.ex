defmodule Slime.Renderer do
  @moduledoc """
  Transform Slime templates into HTML.
  """
  alias Slime.Compiler
  alias Slime.Parser

  @doc """
  Compile Slime template to valid EEx HTML.

  ## Examples
      iex> Slime.Renderer.precompile(~s(input.required type="hidden"))
      "<input class=\\"required\\" type=\\"hidden\\">"
  """
  def precompile(input) do
    input
    |> Parser.parse
    |> Compiler.compile
  end

  @doc """
  Takes a Slime template as a string as well as a set of bindings, and renders
  the resulting HTML.

  Note that this method of rendering is substantially slower than rendering
  precompiled templates created with Slime.function_from_file/5 and
  Slime.function_from_string/5.
  """
  def render(slime, bindings \\ [], opts \\ []) do
    slime
    |> precompile
    |> EEx.eval_string(bindings, opts)
  end
end
