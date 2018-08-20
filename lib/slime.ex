defmodule Slime do
  @moduledoc """
  Slim-like HTML templates.
  """

  alias Slime.Renderer

  defmodule TemplateSyntaxError do
    @moduledoc """
    Syntax exception which may appear during parsing and compilation processes
    """
    defexception [:line, :line_number, :column, message: "Syntax error", source: "INPUT"]

    def message(exception) do
      column = if exception.column == 0, do: 0, else: exception.column - 1
      """
      #{exception.message}
      #{exception.source}, Line #{exception.line_number}, Column #{exception.column}
      #{exception.line}
      #{String.duplicate(" ", column)}^
      """
    end
  end

  defdelegate render(slime),           to: Renderer
  defdelegate render(slime, bindings), to: Renderer

  @doc """
  Generates a function definition from the file contents.
  The kind (`:def` or `:defp`) must be given, the
  function name, its arguments and the compilation options.
  This function is useful in case you have templates but
  you want to precompile inside a module for speed.

  ## Examples

      # sample.slim
      = a + b

      # sample.ex
      defmodule Sample do
        require Slime
        Slime.function_from_file :def, :sample, "sample.slime", [:a, :b]
      end

      # iex
      Sample.sample(1, 2) #=> "3"
  """
  defmacro function_from_file(kind, name, file, args \\ [], opts \\ []) do
    quote bind_quoted: binding() do
      require EEx
      eex = file |> File.read! |> Renderer.precompile
      EEx.function_from_string(kind, name, eex, args, opts)
    end
  end

  @doc """
  Generates a function definition from the string.
  The kind (`:def` or `:defp`) must be given, the
  function name, its arguments and the compilation options.

  ## Examples

      iex> defmodule Sample do
      ...>   require Slime
      ...>   Slime.function_from_string :def, :sample, "= a + b", [:a, :b]
      ...> end
      iex> Sample.sample(1, 2)
      "3"
  """
  defmacro function_from_string(kind, name, source, args \\ [], opts \\ []) do
    quote bind_quoted: binding() do
      require EEx
      eex = source |> Renderer.precompile
      EEx.function_from_string(kind, name, eex, args, opts)
    end
  end
end
