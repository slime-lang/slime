defmodule Slime.Renderer do
  @moduledoc """
  Transform Slime templates into HTML.
  """
  alias Slime.Compiler
  alias Slime.Parser

  import Compiler, only: [eex_delimiters: 0, heex_delimiters: 0]

  @doc """
  Compile Slime template to valid EEx HTML.

  ## Examples
      iex> Slime.Renderer.precompile(~s(input.required type="hidden"))
      "<input class=\\"required\\" type=\\"hidden\\">"
  """
  def precompile(input) do
    input
    |> Parser.parse()
    # |> OriginalCompiler.compile()
    |> Compiler.compile(eex_delimiters())
  end

  @doc """
  Compile Slime template to valid EEx HTML.

  ## Examples
      iex> Slime.Renderer.precompile(~s(input.required type="hidden"))
      "<input class=\\"required\\" type=\\"hidden\\">"
  """
  def precompile_heex(input) do
    input
    |> Parser.parse()
    |> Compiler.compile(heex_delimiters())
  end

  @doc """
  Takes a Slime template as a string as well as a set of bindings, and renders
  the resulting HTML.

  Note that this method of rendering is substantially slower than rendering
  precompiled templates created with Slime.function_from_file/5 and
  Slime.function_from_string/5.

  Note: A HEEx-aware version of render/4 was not included because it would require importing
  Phoenix.LiveView.HTMLEngine, creating a dependency on Phoenix.
  """
  def render(slime, bindings \\ [], opts \\ []) do
    slime
    |> precompile()
    |> EEx.eval_string(bindings, opts)
  end
end
